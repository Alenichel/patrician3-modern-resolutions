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

[assembly: AssemblyTitle("Patrician III Modern Resolutions")]
[assembly: AssemblyDescription("Modern-resolution launcher for the Steam edition")]
[assembly: AssemblyVersion("1.0.2.0")]
[assembly: AssemblyFileVersion("1.0.2.0")]

internal static class Program {
    internal const string Version = "1.0.2";
    internal static readonly string[] Payload = {
        "Install.ps1", "Restore.ps1", "Start-Mod.ps1",
        "src/Apply-ResolutionPatch.ps1", "src/Prepare-Assets.ps1", "src/Mod.Common.ps1",
        "src/Safe-SeaBlit.ps1",
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
                    form.Show();Application.DoEvents();form.DrawToBitmap(preview,new Rectangle(Point.Empty,preview.Size));form.Hide();
                    preview.Save(Path.ChangeExtension(args[1],".png"),System.Drawing.Imaging.ImageFormat.Png);
                }
                File.WriteAllText(args[1], "PASS: embedded payload complete; launcher rendered; Steam discovery="+(IsGame(FindGame())?"found":"not installed")+"; version " + Version);
                return 0;
            }
            if (args.Length == 4 && args[0] == "--worker") return Worker(args[1], args[2], args[3]);
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new Launcher());
            return 0;
        } catch (Exception ex) { MessageBox.Show(ex.Message, "Patrician III Modern Resolutions", MessageBoxButtons.OK, MessageBoxIcon.Error); return 1; }
    }
    internal static string Quote(string value) { return "\"" + value.Replace("\"", "\\\"").TrimEnd('\\') + "\""; }
    internal static bool IsGame(string folder) { return !String.IsNullOrEmpty(folder) && File.Exists(Path.Combine(folder, "Patrician3.exe")) && File.Exists(Path.Combine(folder, "p2arch0_eng.cpr")); }
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
    private static int Worker(string action,string game,string result) {
        int exit=1;
        var log=new StringBuilder();
        string temp=null;
        try {
            if (action!="start" && action!="restore") throw new Exception("Unknown action.");
            if (!new WindowsPrincipal(WindowsIdentity.GetCurrent()).IsInRole(WindowsBuiltInRole.Administrator)) throw new Exception("Administrator privileges are required.");
            game=Path.GetFullPath(game);
            if (!IsGame(game)) throw new Exception("Invalid game folder.");
            if (action=="start" && Screen.PrimaryScreen.Bounds.Size != new Size(3440,1440)) throw new Exception("This release requires the primary display to be set to 3440x1440.");
            temp=Path.Combine(Path.GetTempPath(),"Patrician3ModernResolutions-"+Guid.NewGuid().ToString("N"));
            Directory.CreateDirectory(temp);
            foreach (string path in Payload) {
                string dest=Path.Combine(temp,path.Replace('/',Path.DirectorySeparatorChar)); Directory.CreateDirectory(Path.GetDirectoryName(dest));
                using(Stream input=Assembly.GetExecutingAssembly().GetManifestResourceStream("payload/"+path)) using(FileStream output=File.Create(dest)) input.CopyTo(output);
            }
            string script=Path.Combine(temp,action=="start"?"Start-Mod.ps1":"Restore.ps1");
            string command="$ErrorActionPreference='Stop'; try { & '"+script.Replace("'","''")+"' -GamePath '"+game.Replace("'","''")+"'; exit 0 } catch { Write-Output ($_.Exception.Message); exit 1 }";
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
    readonly Label status=new Label();
    public Launcher() {
        Text="Patrician III Modern Resolutions · "+Program.Version;ClientSize=new Size(700,445);FormBorderStyle=FormBorderStyle.FixedDialog;MaximizeBox=false;StartPosition=FormStartPosition.CenterScreen;Font=new Font("Segoe UI",10);
        var title=new Label {Text="Patrician III Modern Resolutions",Font=new Font("Segoe UI",18,FontStyle.Bold),AutoSize=true,Location=new Point(24,20)};
        var intro=new Label {Text="English Steam edition · 3440 × 1440\nCentered sea map and correctly proportioned side panel.",AutoSize=true,Location=new Point(26,68)};
        var label=new Label {Text="Game folder",AutoSize=true,Location=new Point(26,126)};
        folder.SetBounds(26,153,532,29);folder.ReadOnly=true;folder.Text=Program.FindGame();
        browse.Text="Browse…";browse.SetBounds(568,152,105,31);browse.Click+=delegate {using(var dialog=new FolderBrowserDialog()){dialog.Description="Select the folder containing Patrician3.exe";if(dialog.ShowDialog()==DialogResult.OK)folder.Text=dialog.SelectedPath;}};
        start.Text="Launch mod";start.SetBounds(26,202,190,42);start.Click+=delegate {BeginAction("start");};
        restore.Text="Restore original";restore.SetBounds(228,202,190,42);restore.Click+=delegate {BeginAction("restore");};
        status.SetBounds(26,259,648,30);status.Text=folder.Text.Length==0?"Game not found. Use Browse to select its folder.":"Ready. Close the game before launching or restoring.";
        output.SetBounds(26,296,648,124);output.Multiline=true;output.ReadOnly=true;output.ScrollBars=ScrollBars.Vertical;output.Font=new Font("Consolas",9);
        Controls.AddRange(new Control[]{title,intro,label,folder,browse,start,restore,status,output});
    }
    private async void BeginAction(string action) {
        if(!Program.IsGame(folder.Text)){MessageBox.Show(this,"Select the English Steam edition of Patrician III.");return;}
        if(action=="start" && Screen.PrimaryScreen.Bounds.Size!=new Size(3440,1440)){MessageBox.Show(this,"This release is verified at 3440x1440 only. Set your primary display to that resolution before launching.");return;}
        Directory.CreateDirectory(Program.StateDirectory);File.WriteAllText(Path.Combine(Program.StateDirectory,"game-path.txt"),folder.Text);
        string log=Path.Combine(Program.StateDirectory,"last-operation.log");
        string game=folder.Text;
        start.Enabled=restore.Enabled=browse.Enabled=false;status.Text="Confirm UAC. "+(action=="start"?"Wait for the patch before loading a game…":"Restoring original files…");output.Text="";
        try {
            int exit=await Task.Run(delegate {
                var info=new ProcessStartInfo(Assembly.GetExecutingAssembly().Location,"--worker "+action+" "+Program.Quote(game)+" "+Program.Quote(log));
                info.UseShellExecute=true;info.Verb="runas";info.WindowStyle=ProcessWindowStyle.Hidden;
                using(Process process=Process.Start(info)){process.WaitForExit();return process.ExitCode;}
            });
            output.Text=File.Exists(log)?File.ReadAllText(log):"No log available.";
            status.Text=exit==0?(action=="start"?"Patch active. You can load a game. Keep 1280×1024 selected.":"Original files restored. You can launch normally from Steam."):"Operation failed. See the details below.";
        } catch(Win32Exception ex) {status.Text=ex.NativeErrorCode==1223?"UAC prompt cancelled. No operation was started.":ex.Message;}
        catch(Exception ex){status.Text="Operation failed.";output.Text=ex.Message;}
        finally {start.Enabled=restore.Enabled=browse.Enabled=true;}
    }
}
