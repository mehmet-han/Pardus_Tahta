using Microsoft.Win32;
using System;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Net;
using System.Net.NetworkInformation;
using System.Net.Sockets;
using System.Runtime.InteropServices;
using System.Runtime.Serialization;
using System.Runtime.Serialization.Formatters.Binary;
using System.Security.Cryptography;
using System.ServiceProcess;
using System.Text;
using System.Windows.Forms;

namespace FatihProjesi
{
    class ClassVariable
    {
        public static opt OPS = new opt();
        public const string ApiUrl = "https://api.mebre.com.tr/v4/s_brt.php";
       // public const string ApiClock = "https://saat.mebre.com.tr/_saat.php";
       // public const string wtb = "https://api.mebre.com.tr/v4/wtb.php";
        public static string Vercion = "V2.13";
        public static string SubVersiyon = "1";
        public const string userAgent = "agent_SmartBoart";
        internal static string wbUser = "hcrKd_r";
        internal static string wbPass = "B1Mu?WjG!Ga6";
        public static bool IsSaveData = false,IsFlash = false;
        public static string SilmeDosyasiYolu = @Application.StartupPath + "\\rmw.iha";
        public static string[] SattUrls = new string[] { "time.windows.com", "time.google.com", "time.cloudflare.com", "time.apple.com" };
        public static Random rndm = new Random();
    }
    class Tools
    {

     public static  void StartCtrl(bool bo)
        {
            if (bo)
            {
                try
                {
                    RegistryKey key = Registry.CurrentUser.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Run", true);
                    if (key != null)
                    {
                        key.SetValue("FatihProjesi", "\"" + Application.ExecutablePath + "\"");
                        key.Close();
                    }
                }
                catch { }
            }
        }
        public static void CtrlAltDel(bool bo)
        {
            if (bo)
            {
                try
                {
                    RegistryKey ourKey = Registry.LocalMachine;
                    if (ourKey != null)
                    {
                        ourKey = ourKey.OpenSubKey(@"SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon", true);
                        ourKey.SetValue("AutoRestartShell", 0);
                        ourKey.Close();
                    }
                }
                catch {; }
                try
                {
                    RegistryKey taskm = Registry.CurrentUser.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Policies", true);
                    if (taskm != null)
                    {
                        taskm.CreateSubKey("System", RegistryKeyPermissionCheck.Default);
                        taskm.Close();
                    }
                    RegistryKey taskm2 = Registry.CurrentUser.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Policies\System", true);
                    if (taskm2 != null)
                    {
                        taskm2.SetValue("DisableTaskMgr", 1);
                        taskm2.Close();
                    }
                }
                catch
                {; }
            }
        }

        internal static string cFnc(string s)
        {
            s += "?" + DateTime.Now.ToString();
            s = s.Replace("0", "!g");
            s = s.Replace("1", "gt");
            s = s.Replace("2", "_a");
            s = s.Replace("3", "me");
            s = s.Replace("4", "?b");
            s = s.Replace("5", "_z");
            s = s.Replace("6", "fi");
            s = s.Replace("7", "+d");
            s = s.Replace("8", "da");
            s = s.Replace("9", "|k");
            s = s.Replace(" ", "kz");
            s = s.Replace(".", "?u");
            s = s.Replace(":", "wa");
            return s;
        }

        internal static void checkSystmFolder()
        {
            try
            {
                if (!Directory.Exists(Tools.ProgramFls(1)))
                    Directory.CreateDirectory(Tools.ProgramFls(1));
                if (!File.Exists(Tools.ProgramFls(1) + "\\Systm.sys"))
                    CheckFolder.SaveData();
            }
            catch {; }
        }
        internal static string userKey()
        {
            string Key = "";
            string harfler = "a?A)b(B*cCdD-eEf+FgGhHi[IjJkKm?MlLm]MnNoOpPrRs)StT1*23[456-7890";
            Random rn = new Random();
            for (int i = 0; i < 5; i++)
                Key += harfler[rn.Next(0, harfler.Length - 1)];
            Key += "_";
            for (int i = 0; i < 4; i++)
                Key += harfler[rn.Next(1, harfler.Length - 1)];
            Key += "_";
            for (int i = 0; i < 8; i++)
                Key += harfler[rn.Next(2, harfler.Length - 1)];
            Key += "!";
            for (int i = 0; i < 8; i++)
                Key += harfler[rn.Next(3, harfler.Length - 1)];
            return Key;
        }
        public static string ProgramFls(int which)
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
        public static string Crypto(string val)
        {
            MD5CryptoServiceProvider md5 = new MD5CryptoServiceProvider();
            byte[] dizi = Encoding.UTF8.GetBytes(val);
            dizi = md5.ComputeHash(dizi);
            StringBuilder sb = new StringBuilder();

            foreach (byte ba in dizi)
            {
                sb.Append(ba.ToString("x2").ToLower());
            }
            return sb.ToString();
        }
        static void folderDel()
        {
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
        }
        public static void RemoveSystm()
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
                catch { }
                foreach (ServiceController service in ServiceController.GetServices())
                {
                    if (service.DisplayName == "Microsoft Copyright")
                    {
                        if (service.Status.ToString() != "Stopped")
                            service.Stop();
                        break;
                    }
                }
            }
            catch { }
            try
            {
                RegistryKey key = Registry.CurrentUser.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Run", true);
                key.SetValue("FatihProjesi", "");
                key.Close();
            }
            catch { }
            try
            {

                File.Delete(Tools.ProgramFls(2) + "\\Systm\\Newtonsoft.Json.dll");
                File.Delete(Tools.ProgramFls(2) + "\\Systm\\Newtonsoft.Json.xml");
                File.Delete(Tools.ProgramFls(1) + "\\Systm.sys");
            }
            catch { }
            folderDel();
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
            }

            if (!File.Exists(ClassVariable.SilmeDosyasiYolu))
                File.Create(ClassVariable.SilmeDosyasiYolu);

            Form1.cls = true;

            try
            {
                RegistryKey taskm2 = Registry.CurrentUser.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Policies\System", true);
                if (taskm2 != null)
                {
                    taskm2.SetValue("DisableTaskMgr", 0);
                    taskm2.Close();
                }
            }
            catch { }
            try
            {
                Process.Start(new ProcessStartInfo()
                {
                    Arguments = "/C choice /C Y /N /D Y /T 3 & Del \"" + Application.StartupPath + "\\FatihProjesi.exe\"",
                    WindowStyle = ProcessWindowStyle.Hidden,
                    CreateNoWindow = true,
                    FileName = "cmd.exe"
                });
            }
            catch { }

            try
            {
                File.Delete(Tools.ProgramFls(3) + "\\Systm\\FatihProjesi.exe");
                Directory.Delete(Tools.ProgramFls(2), true);
            }
            catch { }

            UpdateNewVersion.DownloadFile("https://www.mebre.com.tr/exe/Unsinstalll.exe", Application.StartupPath, "Unsinstalll.exe");
            while (UpdateNewVersion.wc.IsBusy)
                Application.DoEvents();
            FileInfo fi = new FileInfo(Application.StartupPath + "\\Unsinstalll.exe");
            if (fi.Length > 1000)
            {
                ProcessStartInfo startInfo = new ProcessStartInfo(string.Concat(Application.StartupPath + "\\", "Unsinstalll.exe"));
                startInfo.Arguments = "DelVal";
                startInfo.UseShellExecute = false;
                System.Diagnostics.Process.Start(startInfo);
            }
        }
       static string cv = "";
        static string[] csp;
        public static string ClockFrmt(string s)
        {
            cv = s;
            csp = s.Split(':');
            if (csp.Length != 2)
                return "";
            if (s.Length < 5)
            {
                if (csp[0].Length < 2)
                    csp[0] = "0" + csp[0];
                if (csp[1].Length < 2)
                    csp[1] = "0" + csp[1];
                cv = csp[0] + ":" + csp[1];
            }
            return cv;
        }
        public static void RunCmd(string cmd,bool bo=true)
        {
            if(bo)
            TastbarWindows.Show();
            System.Diagnostics.Process process = new System.Diagnostics.Process();
            process.StartInfo.WindowStyle = System.Diagnostics.ProcessWindowStyle.Hidden;
            process.StartInfo.FileName = @"C:\WINDOWS\system32\cmd.exe";
            process.StartInfo.Arguments = cmd;
            process.StartInfo.Verb = "runas";
            process.Start();
            if (bo)
                TastbarWindows.Hide();
        }
        static uint SwapEndianness(ulong x)
        {
            return (uint)(((x & 0x000000ff) << 24) +
                       ((x & 0x0000ff00) << 8) +
                       ((x & 0x00ff0000) >> 8) +
                       ((x & 0xff000000) >> 24));
        }
        static Socket socket;
        static string ntpServer;
        static byte[] ntpData = new byte[48];
        static IPEndPoint ipEndPoint;
        public static DateTime GetNetworkTime()
        {
            try
            {
                if (ClassClient.TahtaLock == 0)
                    return DateTime.Now;
                if (!NetworkInterface.GetIsNetworkAvailable())
                    return DateTime.Now;
                Array.Clear(ntpData, 0, 48);
                ntpServer = ClassVariable.SattUrls[ClassVariable.rndm.Next(0, ClassVariable.SattUrls.Length)];
                ntpData[0] = 0x1B;
                var addresses = Dns.GetHostEntry(ntpServer).AddressList;
                ipEndPoint = new IPEndPoint(addresses[0], 123);
                socket = new Socket(AddressFamily.InterNetwork, SocketType.Dgram, ProtocolType.Udp);
                socket.Connect(ipEndPoint);
                socket.ReceiveTimeout = 3000;
                socket.Send(ntpData);
                socket.Receive(ntpData);
                const byte serverReplyTime = 40;
                ulong intPart = BitConverter.ToUInt32(ntpData, serverReplyTime);
                ulong fractPart = BitConverter.ToUInt32(ntpData, serverReplyTime + 4);
                intPart = SwapEndianness(intPart);
                fractPart = SwapEndianness(fractPart);
                var milliseconds = (intPart * 1000) + ((fractPart * 1000) / 0x100000000L);
                var networkDateTime = (new DateTime(1900, 1, 1, 0, 0, 0, DateTimeKind.Utc)).AddMilliseconds((long)milliseconds);
                return networkDateTime.ToLocalTime();
            }
            catch
            {
                return DateTime.Now;
            }
        }
    }
    class CheckFolder
    {
        static string CretaEx()
        {
            string rot = "abcçdefghıijklmnoöprsştuüvyzwxABCÇDEFGĞHIİJKLMNOÖPRSŞTUÜVYZ0123456789";
            Random rn = new Random();
            string d = "";
            for (int i = 0; i < rn.Next(10, 32); i++)
                d += rn.Next(0, rot.Length - 1);
            return d;
        }
        public static void cfolder()
        {
            if (!File.Exists(Tools.ProgramFls(1) + "\\Systm.sys"))
            {
                ClassVariable.OPS.xx = CretaEx();
                ClassVariable.OPS.yy = CretaEx();
                ClassVariable.OPS.cc = CretaEx();
                ClassVariable.OPS.ss = CretaEx();
                ClassVariable.OPS.dd = CretaEx();
                ClassVariable.OPS.k = "0";
                ClassVariable.OPS.t = "0";
                ClassVariable.OPS.p = Tools.Crypto("mebre");
                Random rn = new Random();
                ClassVariable.OPS.b = rn.Next(100, 1000);
                ClassVariable.OPS.c = rn.Next(1000, 10000);
                ClassVariable.OPS.s = rn.Next(10000, 100000);
                ClassVariable.OPS.i = rn.Next(9999, 99999);
                ClassVariable.OPS.a = rn.Next(88888, 888888);
                IFormatter formatter = new BinaryFormatter();
                Directory.CreateDirectory(Tools.ProgramFls(1));
                Stream objfilestream = new FileStream(Tools.ProgramFls(1) + "\\Systm.sys", FileMode.Create, FileAccess.Write, FileShare.None);
                formatter.Serialize(objfilestream, ClassVariable.OPS);
                objfilestream.Close();
            }
        }
        public static void LoadFolder()
        {
            string p = Tools.Crypto("mebre");
            string k = "0";
            string t = "0";
            string tn = "";
            if (File.Exists(Tools.ProgramFls(1) + "\\Systm.sys"))
            {
                try
                {
                    Stream stream = new FileStream(Tools.ProgramFls(1) + "\\Systm.sys", FileMode.Open, FileAccess.Read);
                    IFormatter formatter = new BinaryFormatter();
                    stream.Seek(0, SeekOrigin.Begin);
                    ClassVariable.OPS = (opt)formatter.Deserialize(stream);
                    stream.Close();
                    if ((p != "" && p != Tools.Crypto("mebre")) && (ClassVariable.OPS.p == null || ClassVariable.OPS.p == "mebre" || ClassVariable.OPS.p == Tools.Crypto("mebre")))
                    {
                        ClassVariable.OPS.p = p;
                        ClassVariable.OPS.k = k;
                        ClassVariable.OPS.t = t;
                        ClassVariable.OPS.tn = tn;
                    }
                }
                catch
                {
                    ClassVariable.OPS.p = p;
                    ClassVariable.OPS.k = k;
                    ClassVariable.OPS.t = t;
                    ClassVariable.OPS.tn = tn;
                }
            }
            else
            {
                if ((p != "" && p != Tools.Crypto("mebre")) && (ClassVariable.OPS.p == null || ClassVariable.OPS.p == "mebre" || ClassVariable.OPS.p == Tools.Crypto("mebre")))
                {
                    ClassVariable.OPS.p = p;
                    ClassVariable.OPS.k = k;
                    ClassVariable.OPS.t = t;
                    ClassVariable.OPS.tn = tn;
                }
            }
        }
        public static void SaveData()
        {
            int s = 0;
        rpt:
            try
            {
                s++;
                var path = Tools.ProgramFls(1) + "\\Systm.sys";
                IFormatter formatter = new BinaryFormatter();
                Stream objfilestream = new FileStream(path, FileMode.Create, FileAccess.Write, FileShare.None);
                formatter.Serialize(objfilestream, ClassVariable.OPS);
                objfilestream.Close();
            }
            catch
            {
                if (s == 1)
                {
                    System.Threading.Thread.Sleep(1000);
                    Application.DoEvents();
                    goto rpt;
                }
            }
        }
    }

    [Serializable]
    class opt
    {
        public string[,,] hours = new string[9, 20, 3];
        public int b, c, s, i, a;
        public string t, k, p, tn;
        public string xx, yy, cc, ss, dd;
        public byte[,] Rn = new byte[9, 20];
    }
}
