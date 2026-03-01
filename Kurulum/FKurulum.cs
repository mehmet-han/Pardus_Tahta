using System;
using System.Drawing;
using System.Windows.Forms;
using System.IO;
using System.Diagnostics;
using System.Runtime.Serialization.Formatters.Binary;
using Microsoft.Win32;
using System.ServiceProcess;
using System.Security.Principal;
using System.Runtime.InteropServices;

namespace Kurulum
{
    public partial class FKurulum : Form
    {
        public FKurulum()
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
        
        void SistemiKaldir()
        {
            try
            {
                richTextBox1.Text = "Eski Sistem Kaldırılıyor.";
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
                    if (File.Exists(ProgramFls(2) + "\\Systm\\Newtonsoft.Json.dll"))
                        File.Delete(ProgramFls(2) + "\\Systm\\Newtonsoft.Json.dll");
                    if (File.Exists(ProgramFls(1) + "\\Systm.sys"))
                        File.Delete(ProgramFls(1) + "\\Systm.sys");
                    if (File.Exists(ProgramFls(2) + "\\Systm\\FatihProjesi.exe"))
                        File.Delete(ProgramFls(2) + "\\Systm\\FatihProjesi.exe");
                }
                catch {; }
                string hrf = "abcdefghjklmnoprstuvyxz";
                systm sys = new systm();
                for (int i = 0; i < hrf.Length; i++)
                {
                    for (int s = 0; s < hrf.Length; s++)
                    {
                        Application.DoEvents();
                        if (Directory.Exists("C:\\" + hrf[i] + hrf[s]))
                        {
                            string dn = "C:\\" + hrf[i].ToString() + hrf[s].ToString();
                            try
                            {
                                Directory.Delete(dn, true);
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
                if(Directory.Exists("C:\\Windws"))
                {
                    try
                    {
                        Directory.Delete("C:\\Windws",true);
                    }
                    catch {; }
                }
            }
            catch {; }
        }
        [Serializable]
        class systm
        {
            public int a = 0, b = 1, c = 2, d = 3;
            public string ab = "1", ac = "2", ad = "3";
        }
        int subSay = 0, fileSay = 0;
        void DirectoryCopy(string sourceDirName, string destDirName, bool copySubDirs)
        {
            Application.DoEvents();
            DirectoryInfo dir = new DirectoryInfo(sourceDirName);
            if (dir.Exists)
            {
                DirectoryInfo[] dirs = dir.GetDirectories();
                Directory.CreateDirectory(destDirName);
                FileInfo[] files = dir.GetFiles();
                foreach (FileInfo file in files)
                {
                    Application.DoEvents();
                    fileSay++;
                    if (file.Length < 3051648)
                    {
                        string tempPath = Path.Combine(destDirName, file.Name);
                        file.CopyTo(tempPath, false);
                    }
                    if (fileSay >= 8)
                        break;
                }
                if (copySubDirs)
                {
                    foreach (DirectoryInfo subdir in dirs)
                    {
                        subSay++;
                        if (subSay >= 150)
                            break;
                        string tempPath = Path.Combine(destDirName, subdir.Name);
                        DirectoryCopy(subdir.FullName, tempPath, copySubDirs);
                    }
                }
            }
        }

        void DirektoryCopy()
        {
            string[] FolderArray = Directory.GetDirectories(@"C:\Windows");
            foreach (string dosya in FolderArray)
            {
                subSay = 0;
                fileSay = 0;
                try
                {
                    Application.DoEvents();
                    DirectoryInfo d_i = new DirectoryInfo(dosya);
                    richTextBox1.Text = d_i.FullName;
                    DirectoryCopy(d_i.FullName, ProgramFls(1) + "\\" + d_i.Name, true);
                }
                catch {; }
            }
            string[] FileArray = Directory.GetFiles(@"C:\Windows");
            foreach (string dosya in FileArray)
            {
                try
                {
                    DirectoryInfo d_i = new DirectoryInfo(dosya);
                    if (File.Exists(d_i.FullName))
                        File.Copy(d_i.FullName, ProgramFls(1) + "\\" + d_i.Name);
                }
                catch {; }
            }
        }
        void FolderCreate()
        {
            return;
            string hrf = "abcdefghjklmnoprstuvyxz";
            systm sys = new systm();
            for (int i = 0; i < hrf.Length; i++)
            {
                for (int s = 0; s < hrf.Length; s++)
                {
                    Application.DoEvents();
                    if (!Directory.Exists("C:\\" + hrf[i] + hrf[s]))
                    {
                        Directory.CreateDirectory("C:\\" + hrf[i] + hrf[s]);
                        BinaryFormatter formatter = new BinaryFormatter();
                        Stream objfilestream = new FileStream("C:\\" + hrf[i] + hrf[s] + "\\" + hrf[i] + hrf[s] + ".sys", FileMode.Create, FileAccess.Write, FileShare.None);
                        formatter.Serialize(objfilestream, sys);
                        objfilestream.Close();
                    }
                }
            }
            for (int i = 0; i < hrf.Length; i++)
            {
                for (int s = 0; s < hrf.Length; s++)
                {
                    Application.DoEvents();
                    if (!Directory.Exists("C:\\" + hrf[i] + hrf[i] + hrf[s] + hrf[s]))
                    {
                        Directory.CreateDirectory("C:\\" + hrf[i] + hrf[i] + hrf[s] + hrf[s]);
                        BinaryFormatter formatter = new BinaryFormatter();
                        Stream objfilestream = new FileStream("C:\\" + hrf[i] + hrf[i] + hrf[s] + hrf[s] + "\\" + hrf[i] + hrf[i] + hrf[s] + hrf[s] + ".sys", FileMode.Create, FileAccess.Write, FileShare.None);
                        formatter.Serialize(objfilestream, sys);
                        objfilestream.Close();
                    }
                }
            }
        }
        void RegeditWork()
        {
            try
            {
                RegistryKey registryKey = Registry.CurrentUser.OpenSubKey("Software\\Microsoft\\Internet Explorer\\Main\\FeatureControl\\FEATURE_BROWSER_EMULATION", true);
                registryKey.SetValue("FatihProjesi.exe", 11000, RegistryValueKind.DWord);
                registryKey.Close();
            }
            catch { }

            try
            {
                RegistryKey registryKey = Registry.LocalMachine.OpenSubKey("SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\System", true);
                registryKey.SetValue("EnableLUA", 0, RegistryValueKind.DWord);
                registryKey.Close();
            }
            catch { }

            try
            {
                RegistryKey key = Registry.CurrentUser.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Run", true);
                key.SetValue("FatihProjesi", "\"" + ProgramFls(2) + "\\Systm" + "\"");
                key.Close();
            }
            catch { }

            try
            {
                RegistryKey taskm = Registry.CurrentUser.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Policies", true);
                taskm.CreateSubKey("System", RegistryKeyPermissionCheck.Default);
                taskm.Close();
                RegistryKey taskm2 = Registry.CurrentUser.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Policies\System", true);
                taskm2.SetValue("DisableTaskMgr", 1);
                taskm2.Close();
            }
            catch {; }
        }
        void CopyWork()
        {
            if (!System.IO.Directory.Exists(ProgramFls(2) + "\\Systm\\"))
                Directory.CreateDirectory(ProgramFls(2) + "\\Systm");
            System.IO.File.Copy(Application.StartupPath + "\\Files\\Newtonsoft.Json.dll", ProgramFls(2) + "\\Systm\\Newtonsoft.Json.dll", true);
            System.IO.File.Copy(Application.StartupPath + "\\Files\\FatihProjesi.exe", ProgramFls(2) + "\\Systm\\FatihProjesi.exe", true);
            Application.DoEvents();
            panel2.BackColor = Color.Yellow;
            Application.DoEvents();
            if (!Directory.Exists(ProgramFls(1)))
                Directory.CreateDirectory(ProgramFls(1));
            System.IO.File.Copy(Application.StartupPath + "\\Files\\ConfigServices.exe", ProgramFls(1) + "\\ConfigServices.exe", true);
        }
        void StartWork()
        {
            Application.DoEvents();
            panel3.BackColor = Color.Yellow;
            System.Diagnostics.Process.Start(ProgramFls(2) + "\\Systm\\FatihProjesi.exe");
        }
        void ServiceWork()
        {
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
                System.Threading.Thread.Sleep(3000);

                p = new System.Diagnostics.Process();
                p.StartInfo.FileName = "C:\\WINDOWS\\system32\\cmd.exe";
                p.StartInfo.WorkingDirectory = Path;
                p.StartInfo.Arguments = "/C InstallUtil.exe " + ProgramFls(1) + "\\ConfigServices.exe";
                p.StartInfo.WindowStyle = System.Diagnostics.ProcessWindowStyle.Normal;
                p.StartInfo.CreateNoWindow = false;
                p.StartInfo.RedirectStandardOutput = true;
                p.StartInfo.UseShellExecute = false;
                p.StartInfo.Verb = "runas";
                p.Start();
            }
            else
            {
                richTextBox1.AppendText("Servis Kurulamadı.");
            }
        }
        void CheckService()
        {
            richTextBox1.Text = "Windows Servisleri Kontrol Ediliyor.";
            ServiceController service = new ServiceController("Microsoft Copyright");
            try
            {
               // if(service.Status)
                service.Start();
                panel4.BackColor = Color.Yellow;
            }
            catch {
                richTextBox1.Text = "Servis Başlatılamadı.";
            }

        }

        [DllImport("shell32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool IsUserAnAdmin();
        static bool IsCurrentProcessAdmin()
        {
            return IsUserAnAdmin();
        }

        void StartBatWork(string Name)
        {
            Process.Start("C:\\Windows\\System32\\powercfg", "-change -standby-timeout-dc 0");
            Process.Start("C:\\Windows\\System32\\powercfg", "-Change -monitor-timeout-ac 0");
            Process.Start("C:\\Windows\\System32\\powercfg", "–x -standby-timeout-dc 0");
            Process.Start("C:\\Windows\\System32\\powercfg", "-change -standby-timeout-ac 0");
            Process.Start("C:\\Windows\\System32\\powercfg", "–x -standby-timeout-ac 0");
            Process.Start("C:\\Windows\\System32\\powercfg", "-setacvalueindex SCHEME_CURRENT 4f971e89-eebd-4455-a8de-9e59040e7347 7648efa3-dd9c-4e3e-b566-50f929386280 3");
            Process.Start("C:\\Windows\\System32\\powercfg", "-SetActive SCHEM_CURRENT");
            Process.Start("C:\\Windows\\System32\\powercfg", "-change -standby-timeout-dc 0");

            System.Diagnostics.Process p = new System.Diagnostics.Process();
            p.StartInfo.FileName = "C:\\WINDOWS\\system32\\cmd.exe";
            p.StartInfo.WorkingDirectory = "C:\\WINDOWS\\system32\\";
            p.StartInfo.Arguments = "cmd /K net localgroup administrators "+ Name + " /add";
            p.StartInfo.WindowStyle = System.Diagnostics.ProcessWindowStyle.Hidden;
            p.StartInfo.Verb = "runas";
            p.Start();


            p = new System.Diagnostics.Process();
            p.StartInfo.FileName = "C:\\WINDOWS\\system32\\cmd.exe";
            p.StartInfo.WorkingDirectory = "C:\\WINDOWS\\system32\\";
            p.StartInfo.Arguments = "cmd /K net user " + Name + " /passwordreq:no";
            p.StartInfo.WindowStyle = System.Diagnostics.ProcessWindowStyle.Hidden;
            p.StartInfo.Verb = "runas";
            p.Start();

            p = new System.Diagnostics.Process();
            p.StartInfo.FileName = "C:\\WINDOWS\\system32\\cmd.exe";
            p.StartInfo.WorkingDirectory = "C:\\WINDOWS\\system32\\";
            p.StartInfo.Arguments = "cmd /K net user " + Name + " \"\"";
            p.StartInfo.WindowStyle = System.Diagnostics.ProcessWindowStyle.Hidden;
            p.StartInfo.Verb = "runas";
            p.Start();


            RegistryKey localMachine = RegistryKey.OpenBaseKey(Microsoft.Win32.RegistryHive.LocalMachine, RegistryView.Registry64);
            RegistryKey regKey = localMachine.OpenSubKey(@"SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon", true);
            regKey.SetValue("Userinit", "C:\\pf\\Systm\\FatihProjesi.exe");
            regKey.SetValue("AutoAdminLogon", 0);
            regKey.SetValue("DefaultUserName",  Name);
            regKey.SetValue("DefaultPassword", "");
            regKey.SetValue("AutoRestartShell", 0);
            regKey.Close();
            try
            {
                regKey = localMachine.OpenSubKey(@"SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer", true);
                regKey.SetValue("NoDriveTypeAutoRun", 255);
                regKey.Close();
            }
            catch {; }


            RegistryKey CurrentUser = RegistryKey.OpenBaseKey(Microsoft.Win32.RegistryHive.CurrentUser, RegistryView.Registry64);
            RegistryKey CuruSER = CurrentUser.OpenSubKey(@"Control Panel\Desktop", true);
            CuruSER.SetValue("AutoEndTasks", 1);
            CuruSER.Close();
        }
        private void button1_Click(object sender, EventArgs e)
        {
            if (!IsCurrentProcessAdmin())
            {
                MessageBox.Show("Lütfen Uygulamayı Yönetici Olarak Çalıştırınız.");
                return;
            }
            if (button1.Text == "Sistemi Kur")
            {
                button1.Text = "Lütfen Bekleyiniz...";
                SistemiKaldir();
                Process[] prs = Process.GetProcesses();
                foreach (Process pr in prs)
                {
                    try
                    {
                        if (pr.ProcessName == "FatihProjesi")
                            pr.Kill();
                    }
                    catch {; }
                    Application.DoEvents();
                }
                if (File.Exists(ProgramFls(2) + "\\rmw.iha"))
                    File.Delete(ProgramFls(2) + "\\rmw.iha");
                try
                {
                    StartBatWork(Environment.UserName);
                    DirektoryCopy();
                    FolderCreate();
                    panel1.BackColor = Color.Yellow;
                    CopyWork(); 
                    RegeditWork();
                    System.Threading.Thread.Sleep(5000);
                    ServiceWork();
                    ServiceController service = new ServiceController("Microsoft Copyright");
                    try
                    {
                        service.Start();
                    }
                    catch {; }
                    CheckService();
                    richTextBox1.AppendText("Son 20 Saniye Kaldı.");
                    panel3.BackColor = Color.Yellow;
                    StartWork();
                    Application.DoEvents();
                    System.Threading.Thread.Sleep(12000);
                    panel4.BackColor = Color.Yellow;
                    if (checkBox1.Checked)
                        richTextBox1.AppendText("Kurulum Bitti. Bilgisayarınız Kendini Kapatmazsa Kapatıp Tekrar Açınız.");
                    button1.Text = "Kurulum Tamamladı";
                    Application.DoEvents();
                    if(checkBox1.Checked)
                    {
                        ProcessStartInfo proc = new ProcessStartInfo();
                        proc.WindowStyle = ProcessWindowStyle.Hidden;
                        proc.FileName = "cmd";
                        proc.Arguments = "/C shutdown -f -r -t 0";
                        Process.Start(proc);
                    }
                    else
                    {
                        button1.Text = "Sistemi Kur";
                        Application.Exit();
                    }
                }
                catch
                {
                    SistemiKaldir();
                    MessageBox.Show("Kuruluma Devam Edilemiyor.\n1 : Birden fazla kullanıcı varsa o kullanıcıları silmeniz gerekmektedir.\n2 : regedit e erişim sorunu varsa lütfen önce o sorunu çözünüz.\n3 : Hizmet kurulumu engelleyen bir unsur varsa lütfen o unsuru devre dışı bırakınız.");
                }
            }
        }

        private void FKurulum_Load(object sender, EventArgs e)
        {

            textBox1.Text = ProgramFls(2) + "\\Systm\\FatihProjesi.exe";
        }
        private void button2_Click(object sender, EventArgs e)
        {
            if (Directory.Exists(ProgramFls(2) + "\\Systm"))
                System.Diagnostics.Process.Start("explorer.exe", ProgramFls(2) + "\\Systm");
            else
                MessageBox.Show("Belirtilen Yol Bulunamadı. Sistem Kurulmamış Olabilir.");
        }
    }
}
