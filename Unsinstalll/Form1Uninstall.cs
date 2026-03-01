using Microsoft.Win32;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Linq;
using System.ServiceProcess;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace Unsinstalll
{
    public partial class Form1Uninstall : Form
    {
        public Form1Uninstall()
        {
            InitializeComponent();
        }
        string ProgramFls(int which)
        {
            switch (which)
            {
                case 1: //veritabanı
                    return "C:\\Windws";
                case 2: //FatihProjesi,_usb
                    return "C:\\pf";
                case 3://configure
                    return "C:\\Configure";
                default:
                    return "C:\\pf";
            }
          }
        private void button1_Click(object sender, EventArgs e)
        {
            try
            {
                try
                {
                    RegistryKey localMachine = RegistryKey.OpenBaseKey(Microsoft.Win32.RegistryHive.LocalMachine, RegistryView.Registry64);
                    RegistryKey regKey = localMachine.OpenSubKey(@"SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon", true);
                    regKey.SetValue("Userinit", "C:\\Windows\\System32\\userinit.exe");
                    regKey.Close();
                }
                catch {; }

                try
                {
                    RegistryKey taskm2 = Registry.CurrentUser.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Policies\System", true);
                    taskm2.SetValue("DisableTaskMgr", 0);
                    taskm2.Close();
                }
                catch {; }


                try
                {
                    RegistryKey key = Registry.CurrentUser.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Run", true);
                    key.SetValue("FatihProjesi", "");
                    key.Close();
                }
                catch {; }

                string Path = "";
                if (Directory.Exists(@"C:\Windows\Microsoft.NET\Framework\v4.0.30319"))
                {
                    Path = "C:\\Windows\\Microsoft.NET\\Framework\\v4.0.30319";
                }
                if (Directory.Exists(@"C:\Windows\Microsoft.NET\Framework\v3.5") && Path == "")
                {
                    Path = "C:\\Windows\\Microsoft.NET\\Framework\\v3.5";
                }
                if (Directory.Exists(@"C:\Windows\Microsoft.NET\Framework\v3.0") && Path == "")
                {
                    Path = "C:\\Windows\\Microsoft.NET\\Framework\\v3.0";
                }
                if (Path != "")
                {
                    System.Diagnostics.Process p = new System.Diagnostics.Process();
                    p.StartInfo.FileName = "C:\\WINDOWS\\system32\\cmd.exe";
                    p.StartInfo.WorkingDirectory = Path;
                    p.StartInfo.Arguments = "/C InstallUtil.exe " + ProgramFls(1) + "\\ConfigServices.exe -u";
                    p.StartInfo.WindowStyle = System.Diagnostics.ProcessWindowStyle.Normal;
                    p.StartInfo.CreateNoWindow = false;
                    p.StartInfo.RedirectStandardOutput = true;
                    p.StartInfo.UseShellExecute = false;
                    p.StartInfo.Verb = "runas";
                    p.Start();
                    p.WaitForExit();
                }
                Process[] prs = Process.GetProcesses();
                foreach (Process pr in prs)
                {
                    if (pr.ProcessName == "FatihProjesi")
                    {
                        pr.Kill();
                    }
                }
                try
                {
                    RegistryKey taskm2 = Registry.CurrentUser.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Policies\System", true);
                    taskm2.SetValue("DisableTaskMgr", 0);
                    taskm2.Close();
                }
                catch {; }
                try
                {
                    if (File.Exists(ProgramFls(2) + "\\Systm\\FatihProjesi.exe"))
                        File.Delete(ProgramFls(2) + "\\Systm\\FatihProjesi.exe");
                    if (File.Exists(ProgramFls(2) + "\\Systm\\Newtonsoft.Json.dll"))
                        File.Delete(ProgramFls(2) + "\\Systm\\Newtonsoft.Json.dll");
                    File.Delete(ProgramFls(2) + "\\Systm\\Newtonsoft.Json.xml");
                    if (File.Exists(ProgramFls(2) + "\\Systm\\usp.exe"))
                        File.Delete(ProgramFls(2) + "\\Systm\\usp.exe");
                    File.Delete(ProgramFls(1) + "\\Systm.sys");
                }
                catch {; }
                if (File.Exists(ProgramFls(1) + "\\ConfigServices.exe"))
                {
                    try
                    {
                        File.Delete(ProgramFls(1) + "\\ConfigServices.exe");
                    }
                    catch {; }
                }
                string hrf = "abcdefghjklmnoprstuvyxz";
                for (int i = 0; i < hrf.Length; i++)
                {
                    for (int s = 0; s < hrf.Length; s++)
                    {
                        Application.DoEvents();
                        if (Directory.Exists("C:\\" + hrf[i] + hrf[s]))
                        {
                            try
                            {
                                Directory.Delete("C:\\" + hrf[i] + hrf[s], true);
                            }
                            catch {; }

                        }
                    }
                }
                for (int i = 0; i < hrf.Length; i++)
                {
                    for (int s = 0; s < hrf.Length; s++)
                    {
                        Application.DoEvents();
                        if (Directory.Exists("C:\\" + hrf[i] + hrf[i] + hrf[s] + hrf[s]))
                        {
                            try
                            {
                                Directory.Delete("C:\\" + hrf[i] + hrf[i] + hrf[s] + hrf[s], true);
                            }
                            catch {; }

                        }
                    }
                }
                if (Directory.Exists(ProgramFls(1)))
                {
                    try
                    {
                        Directory.Delete(ProgramFls(1), true);
                    }
                    catch {; }
                }
                if (Directory.Exists(ProgramFls(3)))
                {
                    try
                    {
                        Directory.Delete(ProgramFls(3), true);
                    }
                    catch {; }
                }
                if (File.Exists(ProgramFls(2) + "\\rmw.iha"))
                    File.Delete(ProgramFls(2) + "\\rmw.iha");
              if(!Program.IsRemove)
                MessageBox.Show("SİSTEM TAMAMEN KALDIRILDI.");
            }
            catch (Exception ex)
            {
                if (!Program.IsRemove)
                    MessageBox.Show("Sistem Kaldırma BAŞARISIZ:\n" + ex.Message);
            }
        }
        private void button2_Click(object sender, EventArgs e)
        {
            foreach (ServiceController service in ServiceController.GetServices())
            {
                string na = service.DisplayName;
                if (service.DisplayName == "Microsoft Copyright")
                {
                    if (service.Status.ToString() != "Stopped")
                    {
                        service.Stop();
                        break;
                    }
                    else
                    {
                        break;
                    }
                        
                }
            }
            MessageBox.Show("Servis Durduruldu.");
        }

        private void Form1Uninstall_Load(object sender, EventArgs e)
        {
            if (Program.IsRemove)
            {
                button1_Click(sender, new EventArgs());
                Environment.Exit(0);
            }
        }
    }
}
