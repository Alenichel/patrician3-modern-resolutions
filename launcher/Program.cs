using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Reflection;
using System.Security.Principal;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Windows.Forms;
using Microsoft.Win32;
using System.Web.Script.Serialization;

[assembly: AssemblyTitle("Patrician III Modern Resolutions")]
[assembly: AssemblyDescription("Modern-resolution launcher for the Steam edition")]
[assembly: AssemblyVersion("1.1.1.0")]
[assembly: AssemblyFileVersion("1.1.1.0")]

internal static class Program {
    internal const string Version = "1.1.1";
    internal static readonly string[] Payload = {
        "Install.ps1", "Restore.ps1", "Start-Mod.ps1",
        "src/Apply-ResolutionPatch.ps1", "src/Prepare-Assets.ps1", "src/Mod.Common.ps1",
        "src/Safe-SeaBlit.ps1",
        "src/ResolutionProfiles.ps1", "src/ResolutionProfiles.json", "src/ResolutionPatch.Plan.ps1",
        "src/Launch Patrician Modern Resolutions.cmd"
    };
    internal static string StateDirectory { get { return Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Patrician3ModernResolutions"); } }
    [STAThread] private static int Main(string[] args) {
        try {
            if (args.Length == 2 && args[0] == "--self-test") {
                foreach (string path in Payload) using (Stream input = Assembly.GetExecutingAssembly().GetManifestResourceStream("payload/" + path)) {
                    if (input == null || input.Length == 0) throw new Exception("Missing embedded resource: " + path);
                }
                Application.EnableVisualStyles();Application.SetCompatibleTextRenderingDefault(false);
                using(var form=new Launcher()) using(var preview=new Bitmap(form.Width,form.Height)) {
                    form.VerifyResolutionSelector();form.Show();Application.DoEvents();form.DrawToBitmap(preview,new Rectangle(Point.Empty,preview.Size));form.Hide();
                    preview.Save(Path.ChangeExtension(args[1],".png"),System.Drawing.Imaging.ImageFormat.Png);
                }
                File.WriteAllText(args[1], "PASS: embedded payload complete; launcher rendered; resolution selector/default checked; profiles="+Profiles().Length+"; Steam discovery="+(IsGame(FindGame())?"found":"not installed")+"; version " + Version);
                return 0;
            }
            if (args.Length == 5 && args[0] == "--worker") return Worker(args[1], args[2], args[3], args[4]);
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new Launcher());
            return 0;
        } catch (Exception ex) { MessageBox.Show(ex.Message, "Patrician III Modern Resolutions", MessageBoxButtons.OK, MessageBoxIcon.Error); return 1; }
    }
    internal static string Quote(string value) { return "\"" + value.Replace("\"", "\\\"").TrimEnd('\\') + "\""; }
    internal static bool IsGame(string folder) { return !String.IsNullOrEmpty(folder) && File.Exists(Path.Combine(folder, "Patrician3.exe")) && File.Exists(Path.Combine(folder, "p2arch0_eng.cpr")); }
    internal sealed class ResolutionProfile {
        public ResolutionProfile() {}
        public int width { get; set; }
        public int height { get; set; }
        public bool gameplayVerified { get; set; }
        public override string ToString() { return width+"x"+height; }
    }
    private sealed class ProfileCatalog { public ProfileCatalog() {} public ResolutionProfile[] profiles { get; set; } }
    internal static ResolutionProfile[] Profiles() {
        using(Stream stream=Assembly.GetExecutingAssembly().GetManifestResourceStream("payload/src/ResolutionProfiles.json"))
        using(var reader=new StreamReader(stream)) return new JavaScriptSerializer().Deserialize<ProfileCatalog>(reader.ReadToEnd()).profiles;
    }
    internal static ResolutionProfile CurrentProfile() {
        Size size=Screen.PrimaryScreen.Bounds.Size;
        foreach(var profile in Profiles()) if(size==new Size(profile.width,profile.height))return profile;
        return null;
    }
    internal static string SupportedProfiles() { return String.Join(", ",Array.ConvertAll(Profiles(),p=>p.ToString())); }
    internal static string FindGame() {
        string saved = Path.Combine(StateDirectory, "game-path.txt");
        string legacy = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Patrician3Ultrawide", "game-path.txt");
        if (!File.Exists(saved) && File.Exists(legacy)) saved = legacy;
        if (File.Exists(saved)) { string path=File.ReadAllText(saved).Trim(); if (IsGame(path)) return path; }
        string beside = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);
        if (IsGame(beside)) return beside;
        var steamRoots = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        foreach (string key in new [] { @"HKEY_CURRENT_USER\Software\Valve\Steam", @"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Valve\Steam", @"HKEY_LOCAL_MACHINE\SOFTWARE\Valve\Steam" }) {
            foreach (string value in new [] { "SteamPath", "InstallPath" }) {
                string path=Registry.GetValue(key,value,null) as string; if (!String.IsNullOrEmpty(path)) steamRoots.Add(path);
            }
        }
        steamRoots.Add(Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86), "Steam"));
        var libraries = new HashSet<string>(steamRoots,StringComparer.OrdinalIgnoreCase);
        foreach (string steam in steamRoots) {
            string file=Path.Combine(steam,"steamapps","libraryfolders.vdf");
            if (File.Exists(file)) foreach (Match match in Regex.Matches(File.ReadAllText(file), "\"path\"\\s*\"([^\"]+)\"")) libraries.Add(match.Groups[1].Value.Replace(@"\\", @"\"));
        }
        foreach (string library in libraries) {
            string manifest=Path.Combine(library,"steamapps","appmanifest_33570.acf");
            if (File.Exists(manifest)) {
                Match match=Regex.Match(File.ReadAllText(manifest),"\"installdir\"\\s*\"([^\"]+)\"");
                if (match.Success) { string path=Path.Combine(library,"steamapps","common",match.Groups[1].Value); if (IsGame(path)) return path; }
            }
            string fallback=Path.Combine(library,"steamapps","common","Patrician III"); if (IsGame(fallback)) return fallback;
        }
        return "";
    }
    private static int Worker(string action,string game,string result,string resolution) {
        int exit=1;
        var log=new StringBuilder();
        string temp=null;
        try {
            if (action!="start" && action!="restore") throw new Exception("Unknown action.");
            if (!new WindowsPrincipal(WindowsIdentity.GetCurrent()).IsInRole(WindowsBuiltInRole.Administrator)) throw new Exception("Administrator privileges are required.");
            game=Path.GetFullPath(game);
            if (!IsGame(game)) throw new Exception("Invalid game folder.");
            ResolutionProfile profile=null;
            foreach(var candidate in Profiles()) if(candidate.ToString()==resolution)profile=candidate;
            if (action=="start" && profile==null) throw new Exception("Unsupported selected resolution. Supported: "+SupportedProfiles());
            temp=Path.Combine(Path.GetTempPath(),"Patrician3ModernResolutions-"+Guid.NewGuid().ToString("N"));
            Directory.CreateDirectory(temp);
            foreach (string path in Payload) {
                string dest=Path.Combine(temp,path.Replace('/',Path.DirectorySeparatorChar)); Directory.CreateDirectory(Path.GetDirectoryName(dest));
                using(Stream input=Assembly.GetExecutingAssembly().GetManifestResourceStream("payload/"+path)) using(FileStream output=File.Create(dest)) input.CopyTo(output);
            }
            string script=Path.Combine(temp,action=="start"?"Start-Mod.ps1":"Restore.ps1");
            string dimensions=action=="start"?" -Width "+profile.width+" -Height "+profile.height:"";
            string command="$ErrorActionPreference='Stop'; try { & '"+script.Replace("'","''")+"' -GamePath '"+game.Replace("'","''")+"'"+dimensions+"; exit 0 } catch { Write-Output ($_.Exception.Message); exit 1 }";
            var info=new ProcessStartInfo(Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.System),@"WindowsPowerShell\v1.0\powershell.exe"),"-NoProfile -ExecutionPolicy Bypass -EncodedCommand "+Convert.ToBase64String(Encoding.Unicode.GetBytes(command)));
            info.UseShellExecute=false;info.CreateNoWindow=true;info.RedirectStandardOutput=true;info.RedirectStandardError=true;
            using(Process process=Process.Start(info)) {
                Task<string> stdout=process.StandardOutput.ReadToEndAsync(),stderr=process.StandardError.ReadToEndAsync();
                process.WaitForExit();Task.WaitAll(stdout,stderr);log.AppendLine(stdout.Result);log.AppendLine(stderr.Result);exit=process.ExitCode;
            }
        } catch(Exception ex) {log.AppendLine(ex.Message);}
        finally {
            if(temp!=null && Path.GetFullPath(temp).StartsWith(Path.GetFullPath(Path.GetTempPath()),StringComparison.OrdinalIgnoreCase) && Path.GetFileName(temp).StartsWith("Patrician3ModernResolutions-",StringComparison.Ordinal)) {
                try {Directory.Delete(temp,true);} catch(Exception ex) {log.AppendLine("Temporary cleanup: "+ex.Message);}
            }
            try {File.WriteAllText(result,log.ToString(),Encoding.UTF8);} catch {exit=1;}
        }
        return exit;
    }
}

internal sealed class Launcher : Form {
    readonly TextBox folder=new TextBox(), output=new TextBox();
    readonly Button browse=new Button(), start=new Button(), restore=new Button();
    readonly Label status=new Label(), profileStatus=new Label();
    readonly ComboBox resolution=new ComboBox();
    readonly Image coverImage;
    public Launcher() {
        Text="Patrician III Modern Resolutions · "+Program.Version;ClientSize=new Size(700,675);FormBorderStyle=FormBorderStyle.FixedDialog;MaximizeBox=false;StartPosition=FormStartPosition.CenterScreen;Font=new Font("Segoe UI",10);
        using(Stream stream=Assembly.GetExecutingAssembly().GetManifestResourceStream("artwork/readme-cover.png")) {
            if(stream==null)throw new Exception("The embedded README cover is missing.");
            using(Image source=Image.FromStream(stream)) coverImage=new Bitmap(source);
        }
        var cover=new PictureBox {Image=coverImage,SizeMode=PictureBoxSizeMode.Zoom,BackColor=Color.FromArgb(9,35,43),AccessibleName="Patrician III Modern Resolutions cover",TabStop=false};
        cover.SetBounds(0,0,700,280);
        var detected=Program.CurrentProfile();
        var intro=new Label {Text="Resolution",AutoSize=true,Location=new Point(26,295)};
        resolution.DropDownStyle=ComboBoxStyle.DropDownList;
        resolution.SetBounds(125,291,170,29);
        foreach(var profile in Program.Profiles()) {
            resolution.Items.Add(profile);
            if(detected!=null && profile.ToString()==detected.ToString())resolution.SelectedItem=profile;
        }
        profileStatus.SetBounds(310,295,365,24);
        resolution.SelectedIndexChanged+=delegate {UpdateProfileStatus();};
        UpdateProfileStatus();
        var details=new Label {Text="English Steam edition | UI scale 100% | Default: current display resolution",AutoSize=true,Location=new Point(26,326)};
        var label=new Label {Text="Game folder",AutoSize=true,Location=new Point(26,355)};
        folder.SetBounds(26,382,532,29);folder.ReadOnly=true;folder.Text=Program.FindGame();
        browse.Text="Browse…";browse.SetBounds(568,381,105,31);browse.Click+=delegate {using(var dialog=new FolderBrowserDialog()){dialog.Description="Select the folder containing Patrician3.exe";if(dialog.ShowDialog()==DialogResult.OK)folder.Text=dialog.SelectedPath;}};
        start.Text="Launch mod";start.SetBounds(26,431,190,42);start.Click+=delegate {BeginAction("start");};
        restore.Text="Restore original";restore.SetBounds(228,431,190,42);restore.Click+=delegate {BeginAction("restore");};
        status.SetBounds(26,488,648,30);status.Text=folder.Text.Length==0?"Game not found. Use Browse to select its folder.":"Ready. Close the game before launching or restoring.";
        output.SetBounds(26,525,648,124);output.Multiline=true;output.ReadOnly=true;output.ScrollBars=ScrollBars.Vertical;output.Font=new Font("Consolas",9);
        Controls.AddRange(new Control[]{cover,intro,resolution,profileStatus,details,label,folder,browse,start,restore,status,output});
    }
    protected override void Dispose(bool disposing) {
        if(disposing && coverImage!=null)coverImage.Dispose();
        base.Dispose(disposing);
    }
    internal void VerifyResolutionSelector() {
        var current=Program.CurrentProfile();
        var initial=resolution.SelectedItem as Program.ResolutionProfile;
        if((current==null)!=(initial==null) || (current!=null && current.ToString()!=initial.ToString()))throw new Exception("Incorrect default resolution.");
        foreach(var profile in Program.Profiles()) {
            bool found=false;
            foreach(Program.ResolutionProfile item in resolution.Items) if(item.ToString()==profile.ToString()) {resolution.SelectedItem=item;found=true;break;}
            if(!found || ((Program.ResolutionProfile)resolution.SelectedItem).ToString()!=profile.ToString())throw new Exception("Resolution selection failed.");
        }
        resolution.SelectedItem=initial;
    }
    private void UpdateProfileStatus() {
        var selected=resolution.SelectedItem as Program.ResolutionProfile;
        profileStatus.Text=selected==null?"Select a supported resolution":selected.gameplayVerified?"Gameplay verified":"In-game validation pending";
    }
    private async void BeginAction(string action) {
        if(!Program.IsGame(folder.Text)){MessageBox.Show(this,"Select the English Steam edition of Patrician III.");return;}
        var selected=resolution.SelectedItem as Program.ResolutionProfile;
        if(action=="start" && selected==null){MessageBox.Show(this,"Select a supported resolution.");return;}
        string selectedResolution=selected==null?"restore":selected.ToString();
        Directory.CreateDirectory(Program.StateDirectory);File.WriteAllText(Path.Combine(Program.StateDirectory,"game-path.txt"),folder.Text);
        string log=Path.Combine(Program.StateDirectory,"last-operation.log");
        string game=folder.Text;
        start.Enabled=restore.Enabled=browse.Enabled=resolution.Enabled=false;status.Text="Confirm UAC. "+(action=="start"?"Wait for the patch before loading a game…":"Restoring original files…");output.Text="";
        try {
            int exit=await Task.Run(delegate {
                var info=new ProcessStartInfo(Assembly.GetExecutingAssembly().Location,"--worker "+action+" "+Program.Quote(game)+" "+Program.Quote(log)+" "+Program.Quote(selectedResolution));
                info.UseShellExecute=true;info.Verb="runas";info.WindowStyle=ProcessWindowStyle.Hidden;
                using(Process process=Process.Start(info)){process.WaitForExit();return process.ExitCode;}
            });
            output.Text=File.Exists(log)?File.ReadAllText(log):"No log available.";
            status.Text=exit==0?(action=="start"?"Patch active. You can load a game. Keep 1280×1024 selected.":"Original files restored. You can launch normally from Steam."):"Operation failed. See the details below.";
        } catch(Win32Exception ex) {status.Text=ex.NativeErrorCode==1223?"UAC prompt cancelled. No operation was started.":ex.Message;}
        catch(Exception ex){status.Text="Operation failed.";output.Text=ex.Message;}
        finally {start.Enabled=restore.Enabled=browse.Enabled=resolution.Enabled=true;}
    }
}
