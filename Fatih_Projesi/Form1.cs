using Microsoft.Win32;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.ComponentModel;
using System.Diagnostics;
using System.Drawing;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.NetworkInformation;
using System.Runtime.InteropServices;
using System.Runtime.Serialization.Formatters.Binary;
using System.ServiceProcess;
using System.Text;
using System.Threading;
using System.Windows.Forms;

namespace FatihProjesi
{
    public partial class Form1 : Form
    {
        protected override CreateParams CreateParams
        {
            get
            {
                var createParams = base.CreateParams;
                createParams.ExStyle |= 0x80;
                return createParams;
            }
        }
        [StructLayout(LayoutKind.Sequential)]
        private struct KeyboardDLLStruct
        {
            public Keys key;
            public int scanCode;
            public int flags;
            public int time;
            public IntPtr extra;
        }
        private delegate IntPtr LowLevelKeyboardProc(int nCode, IntPtr wParam, IntPtr lParam);
        [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        private static extern IntPtr SetWindowsHookEx(int id, LowLevelKeyboardProc callback, IntPtr hMod, uint dwThreadId);
        [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        private static extern bool UnhookWindowsHookEx(IntPtr hook);
        [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        private static extern IntPtr CallNextHookEx(IntPtr hook, int nCode, IntPtr wp, IntPtr lp);
        [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        private static extern IntPtr GetModuleHandle(string name);
        [DllImport("user32.dll", CharSet = CharSet.Auto)]
        private static extern short GetAsyncKeyState(Keys key);
        private IntPtr ptrHook;
        private LowLevelKeyboardProc objKeyboardProcess;
        public Form1()
        {
            ProcessModule objCurrentModule = Process.GetCurrentProcess().MainModule;
            objKeyboardProcess = new LowLevelKeyboardProc(captureKey);
            ptrHook = SetWindowsHookEx(13, objKeyboardProcess, GetModuleHandle(objCurrentModule.ModuleName), 0);
            InitializeComponent();
            textBox1.Visible = !tmost;
            Control.CheckForIllegalCrossThreadCalls = false;
        }
        public static bool tmost = true, tmostLocOk = true;

        public static bool systmlock = true;
        static string GunuAl = "", CikisSaati = "", Saat = "";
        static int Gun = 1, random = 5, say = 0, ssy = 0, dkk = 0;
        static bool stms = false, insp = true,kmtok = true, loadok = false;
        public static Random rnClent = new Random();
        public static bool IsLoad, cls = false, startWork = false;
        public static DateTime Tarih = new DateTime();
        static DateTime t1 = new DateTime();
        static DateTime t2 = new DateTime();
        static DateTime ShutDownCtrl = new DateTime();
        private IntPtr captureKey(int nCode, IntPtr wp, IntPtr lp)
        {
            if (!systmlock)
                return CallNextHookEx(ptrHook, -1, wp, lp);
            if (tmost)
            {
                if (nCode >= 0)
                {
                    KeyboardDLLStruct objKeyInfo = (KeyboardDLLStruct)Marshal.PtrToStructure(lp, typeof(KeyboardDLLStruct));
                    if (objKeyInfo.key == Keys.RWin || objKeyInfo.key == Keys.LWin || objKeyInfo.key == Keys.F4 || objKeyInfo.key == Keys.Tab || objKeyInfo.key == Keys.Alt || objKeyInfo.key == Keys.Escape)
                        return (IntPtr)1;
                }
                return CallNextHookEx(ptrHook, nCode, wp, lp);
            }
            else
            {
                return CallNextHookEx(ptrHook, nCode, wp, lp);
            }
        }

        void ThreadSet()
        {
            timer2.Enabled = false;
            KillWorker(200);
            ClassClient.NullVal(-6);
            if (systmlock)
                ClassClient.SetValue("open_close", "1");
            if (!systmlock)
                ClassClient.SetValue("open_close", "0");
            timer2.Enabled = true;
        }
        void LogSave(string logname, bool boo)
        {
            if (logname.Trim() == ""&& !boo)
                return;
            try
            {
                string fileName = @"C:\Logs\lgs1.txt";
                if (!boo)
                {
                    if (!Directory.Exists(@"C:\Logs"))
                        Directory.CreateDirectory(@"C:\Logs");
                    if (File.Exists(fileName))
                    {
                        FileInfo fi = new FileInfo(fileName);
                        if (fi.Length > 525824)
                            File.Delete(fileName);
                    }
                    FileStream fs = new FileStream(fileName, FileMode.OpenOrCreate, FileAccess.Write);
                    fs.Close();
                    File.AppendAllText(fileName, Environment.NewLine + logname);
                }
                if (boo)
                {
                    StreamReader sr = new StreamReader(fileName);
                    string Values = sr.ReadToEnd();
                    string[] val = Values.Split('\n');
                    string SentVal = "";
                    sr.Close();
                    try
                    {
                        for (int i = 0; i < 50; i++)
                        {
                            if (i >= val.Length - 1)
                                break;
                            SentVal += val[val.Length - (i + 1)] + "\n";
                        }
                    }
                    catch {; }
                    ClassClient.lname = SentVal;
                    ClassClient.vname = "logistek";
                    ClassClient.save();
                    File.Delete(fileName);
                }
            }
            catch
            { }
        }

        void KillWorker(int delay=600)
        {
            try
            {
                backgroundWorker1.CancelAsync();
                backgroundWorker1.Dispose();
            }
            catch {; }
            try
            {
                backgroundWorker2.CancelAsync();
                backgroundWorker2.Dispose();
            }
            catch {; }
            try
            {
                backgroundWorker3.CancelAsync();
                backgroundWorker3.Dispose();
            }
            catch {; }
            System.Threading.Thread.Sleep(delay);
            Application.DoEvents();
        }
        private const int APPCOMMAND_VOLUME_MUTE = 0x80000;
        private const int APPCOMMAND_VOLUME_UP = 0xA0000;
        private const int APPCOMMAND_VOLUME_DOWN = 0x90000;
        private const int WM_APPCOMMAND = 0x319;
        [DllImport("user32.dll")]
        public static extern IntPtr SendMessageW(IntPtr hWnd, int Msg, IntPtr wParam, IntPtr lParam);
        private void VD()
        {
            SendMessageW(this.Handle, WM_APPCOMMAND, this.Handle, (IntPtr)APPCOMMAND_VOLUME_DOWN);
        }
        private void VU()
        {
            SendMessageW(this.Handle, WM_APPCOMMAND, this.Handle, (IntPtr)APPCOMMAND_VOLUME_UP);
        }
        private void VM()
        {
            SendMessageW(this.Handle, WM_APPCOMMAND, this.Handle, (IntPtr)APPCOMMAND_VOLUME_MUTE);
        }
        public void LockFree(string sbp, bool boo)
        {
            startWork = false;
            timer2.Enabled = false;
            KillWorker(200);
            LogSave(sbp, boo);
            foreach (Form f in Application.OpenForms)
            {
                if (f.Name != "Form1")
                {
                    try
                    {
                        f.Close();
                        f.Dispose();
                    }
                    catch { }
                }
            }
            TastbarWindows.Show();
            systmlock = false;//kilit açıldı
            bool bo = true;
            int ct = 0;
            while (bo)
            {
                try
                {
                    Process[] prs = Process.GetProcesses();
                    foreach (Process pr in prs)
                    {
                        if (pr.ProcessName == "explorer")
                        {
                            bo = false;
                            break;
                        }
                    }
                    if (bo)
                    {
                        TastbarWindows.Show();
                        System.Diagnostics.Process.Start("C:\\Windows\\explorer.exe");
                    }
                }
                catch
                { ct++; }
                if (ct > 200)
                    bo = false;
                if (!bo)
                    break;
            }
            for (int i = 0; i <= 50; i++)
                VU();

            if(!ClassVariable.IsFlash)
                ThreadSet();
            TastbarWindows.Show();
            this.WindowState = FormWindowState.Minimized;
            startWork = true;
            timer2.Enabled = true;
        }
        void LockSystm(string sbp, bool boo)
        {
            startWork = false;
            timer2.Enabled = false;
            KillWorker(200);
            KillAllItem();
            TastbarWindows.Hide();
            LogSave(sbp, boo);
            systmlock = true;
            this.Show();
            this.WindowState = FormWindowState.Maximized;
            this.MinimumSize = new Size(this.Size.Width, this.Size.Height);
            this.TopMost = tmost;
            VM();
            for (int i = 100; i >= 0; i--)
                VD();
            ThreadSet();
            startWork = true;
            timer2.Enabled = true;
        }
        private void button1_Click(object sender, EventArgs e)
        {
            stms = false;
            FormPass yeni = new FormPass();
            yeni.ShowDialog(this);
            try
            {
                yeni.Dispose();
            }
            catch {; }
            foreach (Form f in Application.OpenForms)
            {
                if (f.Name != "Form1")
                {
                    try
                    {
                        f.Close();
                        f.Dispose();
                    }
                    catch {; }
                }
            }
            if (!tmostLocOk)
                FormPass.LockOk = true;
            if (FormPass.LockOk)
            {
                ClassClient.shutDown = -1;
                ClassClient.TahtaLock = -1;
                ClassClient.SystemRemove = -1;
                ClassClient.Message = "";
                LockFree("İnternetsiz Şifre İle Açıldı " + Tarih,false);
            }
            this.TopMost = tmost;
            stms = true;
        }

        private void Form1_Load(object sender, EventArgs e)
        {
            loadok = false;
            ClassVariable.IsFlash = false;
            if (File.Exists(Application.StartupPath + "\\Updater1.exe"))
            {
                try
                {
                    File.Delete(Application.StartupPath + "\\Updater1.exe");
                }
                catch {; }
            }
            ClassClient.tg = false;
            ServicePointManager.Expect100Continue = true;
            ServicePointManager.SecurityProtocol = (SecurityProtocolType)768 | (SecurityProtocolType)3072;
            stms = true;
            kmtok = true;
            Tarih = Tools.GetNetworkTime();
            ShutDownCtrl = Convert.ToDateTime(Tarih.ToShortDateString() + " 00:00:00");
            this.MinimumSize = new Size(MaximizedBounds.Width, MaximizedBounds.Height);
            this.TopMost = tmost;
            CheckFolder.cfolder();
            CheckFolder.LoadFolder();
            label3.Text = "[" + ClassVariable.Vercion + "] " + ClassVariable.OPS.tn;
            Tools.StartCtrl(tmost);
            Tools.CtrlAltDel(tmost);
            loadok = true;
            for (int i = 0; i < kSaat.Length; i++)
                kSaat[i] = 0;
            Form1_Activated(sender, new EventArgs());
        }
        string GetInsTime(DateTime time, string csaati)
        {
            try
            {
                DateTime DtPls = DateTime.Now;
                DateTime Dtpls1 = Convert.ToDateTime(time.ToShortDateString() + " " + csaati);
                DtPls = Dtpls1.AddMinutes(-20);
                return Tools.ClockFrmt(DtPls.Hour + ":" + DtPls.Minute);
            }
            catch
            {
                DateTime Dtpls1 = DateTime.Now;
                return Dtpls1.AddMinutes(-5).ToString();
            }
        }
        static int[] kSaat = new int[20];
        void timer1Thread()
        {
            try
            {
                if (ClassVariable.IsFlash)
                    return;
                if (Tarih.GetType() != typeof(DateTime))
                    return;
                if (Tarih.Year < 2021)
                    return;
                if (Tarih.Year < DateTime.Now.Year)
                    return;
                GunuAl = CultureInfo.GetCultureInfo("tr-TR").DateTimeFormat.DayNames[(int)Tarih.DayOfWeek];
                Gun = 1;
                switch (GunuAl)
                {
                    case "Pazartesi":
                        Gun = 1;
                        break;
                    case "Salı":
                        Gun = 2;
                        break;
                    case "Çarşamba":
                        Gun = 3;
                        break;
                    case "Perşembe":
                        Gun = 4;
                        break;
                    case "Cuma":
                        Gun = 5;
                        break;
                    case "Cumartesi":
                        Gun = 6;
                        break;
                    case "Pazar":
                        Gun = 7;
                        break;
                }
                CikisSaati = "";
                Saat = Tools.ClockFrmt(Tarih.Hour + ":" + Tarih.Minute);
                if (!systmlock)//sistem açıksa
                {
                    for (int i = 1; i < 19; i++)
                    {
                        CikisSaati = "";
                        if (ClassVariable.OPS.hours[Gun, i, 2] != null && ClassVariable.OPS.hours[Gun, i, 2] != "")
                            CikisSaati = Tools.ClockFrmt(ClassVariable.OPS.hours[Gun, i, 2]);
                        
                        if (CikisSaati != "" && CikisSaati.Length == 5)
                        {
                            if (!systmlock)
                            {
                                if (kSaat[i] == 0&&Saat == CikisSaati)
                                {
                                    kSaat[i] = 1;
                                    isKapat = true;
                                    LogMess = "Teneffüs Olduğu İçin Kapatıldı " + Tarih;
                                    LogBoll = false;
                                    break;
                                }
                                else
                                {
                                    t1 = Convert.ToDateTime(Saat);
                                    t2 = Convert.ToDateTime(CikisSaati);
                                    TimeSpan Sonuc = t1 - t2;
                                    if (kSaat[i] == 0&&Sonuc.TotalMinutes > 2 && Sonuc.TotalMinutes < 5)
                                    {
                                        kSaat[i] = 1;
                                        isKapat = true;
                                        LogMess = "Teneffüs Olduğu İçin Kapatıldı " + Tarih;
                                        LogBoll = false;
                                        break;
                                    }
                                }
                            }
                            if (insp)
                            {
                                if (Saat == GetInsTime(Tarih, CikisSaati))
                                {
                                    ClassClient.GetInspc(i, Gun);
                                    insp = false;
                                }
                            }
                            if (insp)
                            {
                                if (Saat == GetInsTime(Tarih.AddMinutes(-1), CikisSaati))
                                {
                                    ClassClient.GetInspc(i, Gun);
                                    insp = false;
                                }
                            }
                        }
                    }
                }
            }
            catch(Exception ex)
            {
               // ClassClient.LogSave(ex.Message, "timer1Thread");
            }
        }

        void CliendWork()
        {
            say++;
            if (say >= random)
            {
                say = 0;
                random = rnClent.Next(1, 3);
                ClassClient.CtrlPost();
            }
        }
        void GetTimeWork()
        {
            try
            {
                Tarih = Tools.GetNetworkTime();
                ssy++;
                if (ssy >= 60)
                {
                    dkk++;
                    insp = true;
                    ssy = 0;
                }
                if (dkk % 5 == 0)
                {
                    if (ClassClient.tg)
                        Tools.checkSystmFolder();
                    if (systmlock && Tarih.GetType() == typeof(DateTime) && Tarih.Hour != DateTime.Now.Hour)
                    {
                        TastbarWindows.Show();
                        Tools.RunCmd("/C date " + Tarih.Day + "/" + Tarih.Month + "/" + Tarih.Year, false);
                        Tools.RunCmd("/C time " + Tarih.Hour + ":" + Tarih.Second, false);
                        try
                        {
                            RegistryKey registryKey = Registry.LocalMachine.OpenSubKey(@"SYSTEM\CurrentControlSet\Services\W32Time\Parameters", true);
                            registryKey.SetValue("Type", "NTP");
                            registryKey.Close();
                        }
                        catch { }
                        TastbarWindows.Hide();
                    }
                }
            }
            catch (Exception ex)
            { ClassClient.LogSave(ex.Message, "timer2_Tick"); }
            if (Tarih.GetType() != typeof(DateTime))
                Tarih = DateTime.Now;
        }
        void CheckInternetWork()
        {
            if (ssy % 3 == 0)
            {
                if (!NetworkInterface.GetIsNetworkAvailable())
                    label3.Text = "İNTERNET YOK!!!";
                else
                    if (label3.Text == "İNTERNET YOK!!!")
                    label3.Text = "[" + ClassVariable.Vercion + "] " + ClassVariable.OPS.tn;

                if (ClassVariable.OPS.t != "0" && ClassVariable.OPS.k != "0" && AcKapa())
                    if (systmlock)
                        LockFree("USB İLE AÇILDI ", false);
                if (Rsystm())
                    Tools.RemoveSystm();
            }
        }
        void KillAllItem()
        {
            try
            {
                if(tmost)
                {
                    Process[] prs = Process.GetProcesses();
                    foreach (Process pr in prs)
                    {
                        if (pr.ProcessName == "chrome")
                            pr.Kill();
                        if (pr.ProcessName == "MicrosoftEdge")
                            pr.Kill();
                        if (pr.ProcessName == "firefox")
                            pr.Kill();
                        if (pr.ProcessName == "opera")
                            pr.Kill();
                        if (pr.ProcessName == "msedge")
                            pr.Kill();
                        if (pr.ProcessName == "iexplore")
                            pr.Kill();
                    }
                }
            }
            catch
            {; }
        }

        private void backgroundWorker1_DoWork(object sender, DoWorkEventArgs e)
        {
            GetTimeWork();
        }
        private void backgroundWorker2_DoWork(object sender, DoWorkEventArgs e)
        {
            try
            {
                CheckInternetWork();
                if (ssy > 0 && ssy % 2 == 0)
                    timer1Thread();
            }
            catch
            {; }
           if (stms && systmlock)
                this.TopMost = tmost;
        }
        private void backgroundWorker3_DoWork(object sender, DoWorkEventArgs e)
        {
            CliendWork();
        }
        void CtrlNetworkVal()
        {
            if (Tarih >= ShutDownCtrl && Tarih <= ShutDownCtrl.AddMinutes(30))
            {
                LogSave("Gece Yarısı Olduğu İçin Kapatıldı." + Tarih, false);
                systmlock = true;
                ThreadSet();
                cls = true;
                Process.Start("shutdown", "/s /f /t 0");
                return;
            }
            if (ClassClient.Message != "" && ClassClient.Message != null)
            {
                if(label2.Text!= ClassClient.Message)
                {
                    timer2.Stop();
                    if (!systmlock)
                    {
                        LockSystm("Yönetimden Mesaj Geldiği İçin Kapatıldı " + Tarih,false);
                    }
                    if (ClassClient.Message != "" && ClassClient.Message != null)
                    {
                        label2.Text = ClassClient.Message;
                        label2.Visible = true;
                    }
                    timer2.Start();
                }
            }
            if (ClassClient.shutDown == 1)
            {
                LogSave("Kapatma İsteği Geldiği İçin Kapatıldı." + Tarih, false);
                timer2.Stop();
                ClassClient.SetValue("shutdown", "0");
                ClassClient.SetValue("open_close", "1");
                cls = true;
                Process.Start("shutdown", "/s /f /t 0");
                Environment.Exit(0);
            }
            if (ClassClient.LogSend == 1)
            {
                timer2.Stop();
                LogSave("Log İsteği Yapıldı", true);
                ClassClient.LogSend = 0;
                timer2.Start();
            }
            if (ClassClient.TahtaLock == 1 && !systmlock && ClassClient.Message == "")
            {
                LockSystm("Mobilden veya Programdan İstek Geldiği İçin Kapatıldı " + Tarih, false);
            }
            if (ClassClient.TahtaLock == 0 && systmlock && ClassClient.Message == "")
            {
                LockFree("Mobilden veya Programdan İstek Geldiği İçin Açıldı " + Tarih,false);
            }
            if (ClassClient.SystemRemove == 1)
            {
                LogSave("Sistemi Kaldırma Komutu Geldiği İçin Sistem Kaldırıldı." + Tarih, false);
                timer2.Enabled = false;
                systmlock = false;
                ClassClient.SetValue("open_close", "0");
                ClassClient.SetValue("shutdown", "0");
                ClassClient.SetValue("system_Remove", "0");
                try
                {
                    Tools.RemoveSystm();
                }
                catch {; }
                cls = true;
                Environment.Exit(0);
            }
        }
        static int ewt = 0;

        static string LogMess = "";
        static bool LogBoll = false;
        static bool isKapat = false, isAc = false;

        private void timer2_Tick(object sender, EventArgs e)
        {
            try
            {
                if (startWork)
                {
                    if (dkk >= 25)
                    {
                        try
                        {
                            backgroundWorker1.CancelAsync();
                            backgroundWorker2.CancelAsync();
                            backgroundWorker3.CancelAsync();
                        }
                        catch {; }
                        timer2.Stop();
                        ClassClient.tg = false;
                        ClassClient.GetValues();
                        ClassClient.tg = true;
                        dkk = 0;
                        timer2.Start();
                    }
                    else
                    {
                        if (!backgroundWorker1.IsBusy)
                            backgroundWorker1.RunWorkerAsync();
                        if (!backgroundWorker2.IsBusy)
                            backgroundWorker2.RunWorkerAsync();
                        if (startWork && !backgroundWorker3.IsBusy)
                            backgroundWorker3.RunWorkerAsync();
                        try
                        {
                            if (startWork)
                                CtrlNetworkVal();
                        }
                        catch { timer2.Start(); }
                    }
                }
                else
                {
                    ewt++;
                    if (ewt >= 4)
                    {
                        ewt = 0;
                        startWork = true;
                    }
                }
            }
            catch { timer2.Start(); }
            if (Tarih.GetType() == typeof(DateTime))
                label1.Text = Tarih.ToString();
            else
                label1.Text = "TARİH : NULL\nSAAT : NULL";

            if (isKapat)
            {
                LockInit();
                LockSystm(LogMess, LogBoll);
                LockInit();
                isKapat = false;
            }
            if (isAc)
            {
                LockInit();
                LockFree(LogMess, LogBoll);
                LockInit();
                isAc = false;
            }
            Application.DoEvents();
            Memory_Class.FlushMemory();

        }
        private void Form1_FormClosing(object sender, FormClosingEventArgs e)
        {
            if (!cls)
            {
                e.Cancel = true;
                this.TopMost = tmost;
            }
            else
            {
                systmlock = true;
                ThreadSet();
            }
        }
        private void Form1_Activated(object sender, EventArgs e)
        {
            if (loadok)
            {
                loadok = false;
                Application.DoEvents();
                LockSystm("Sistem Açılışında Kapatıldı " + DateTime.Now, false);
                timer2.Enabled = false;
                systmlock = true;
                IsLoad = false;
                ClassClient.GetValues();
                IsLoad = true;
                string Nw = ClassClient.vck();
                if (Nw != "" && Nw != null && Nw.Length < 6 && Nw != ClassVariable.Vercion)
                {
                    label6.Text = "Yeni Vesyion Bulundu " + ClassVariable.Vercion + " < " + Nw;
                    label6.Visible = true;
                    button2.Visible = true;
                }
                startWork = true;
                timer2.Enabled = true;
            }
        }
        private void sistemiKontrolEtToolStripMenuItem_Click(object sender, EventArgs e)
        {

        }
        private void Form1_Resize(object sender, EventArgs e)
        {
            if (FormWindowState.Minimized == WindowState)
            {
                this.Hide();
                notifyIcon1.Visible = true;
                notifyIcon1.Text = "Mebre Akıllı Tahta";
                notifyIcon1.BalloonTipTitle = "Program Çalışıyor";
                notifyIcon1.BalloonTipText = "Program sağ alt köşede konumlandı.";
                notifyIcon1.BalloonTipIcon = ToolTipIcon.Info;
                notifyIcon1.ShowBalloonTip(30000);
            }
        }
        private void notifyIcon1_MouseDoubleClick(object sender, MouseEventArgs e)
        {
            if(!ClassVariable.IsFlash)
            {
                this.Show();
                LockSystm("Manuel Kilitlendi " + Tarih,false);
                notifyIcon1.Visible = false;
            }
        }

        private void girişÇıkışSaatleriToolStripMenuItem_Click(object sender, EventArgs e)
        {
            FormGirisCikisSaatleri yeni = new FormGirisCikisSaatleri();
            yeni.ShowDialog(this);
            yeni.Dispose();
        }

        private void komutPenceresiniAÇKAPATToolStripMenuItem_Click(object sender, EventArgs e)
        {
            textBox1.Visible = !textBox1.Visible;
            if (!textBox1.Visible)
                startWork = true;
            textBox1.Focus();
        }

        private void sistemiKontrolEtToolStripMenuItem1_Click(object sender, EventArgs e)
        {
            LogSave("Sistem Kontrolü Yapıldı " + Tarih, false);
            timer2.Enabled = false;
            CheckFolder.SaveData();
            KillWorker();

            ServiceController service = new ServiceController("Microsoft Copyright");
            try
            {
                if (service.Status.ToString() != "Stopped")
                {
                    service.Stop();
                    System.Threading.Thread.Sleep(4000);
                }
                service.Start();
            }
            catch
            {
                ;
            }
            try
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
                p.StartInfo.Arguments = "cmd /K net localgroup administrators " + Name + " /add";
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
                regKey.SetValue("Userinit", "C:\\pf\\Systm\\FatihProjesi.exe", RegistryValueKind.String);
                regKey.SetValue("AutoAdminLogon", 0);
                regKey.SetValue("DefaultUserName", Name);
                regKey.SetValue("DefaultPassword", "");
                regKey.SetValue("AutoRestartShell", 0);
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
            catch {; }
            ClassClient.GetValues();
            timer2.Enabled = true;
            MessageBox.Show(this, "İşlem Başarıyla Gerçekleştirildi.");
        }

        private void sistemAyarlarıToolStripMenuItem_Click(object sender, EventArgs e)
        {
            stms = false;
            FormSettings yeni = new FormSettings();
            yeni.ShowDialog(this);
            try
            {
                yeni.Dispose();
            }
            catch {; }
            stms = true;
            label3.Text = "[" + ClassVariable.Vercion + "] " + ClassVariable.OPS.tn;
        }

        private void logKayıtlarıToolStripMenuItem_Click(object sender, EventArgs e)
        {
            FormLogKayitlari yeni = new FormLogKayitlari();
            yeni.ShowDialog(this);
            yeni.Dispose();
        }
        private void uygulamayıYenidenBaşlatToolStripMenuItem_Click(object sender, EventArgs e)
        {
            cls = true;
            LogSave("Uygulama Yeniden Başlatıldı "+Tarih,false);
            Application.Restart();
        }


        bool AcKapa()
        {
            using (IEnumerator<DriveInfo> enumerator = (
                from u in (IEnumerable<DriveInfo>)DriveInfo.GetDrives()
                where u.DriveType == DriveType.Removable
                select u).GetEnumerator())
            {
                while (enumerator.MoveNext())
                {
                    DriveInfo current = enumerator.Current;
                    try
                    {
                        if (File.ReadAllText(string.Concat(current.RootDirectory, "pass.txt")).Trim() == "32541kehİUFali_veli_hüseyin?İ44EHEJSTRİHTEMES5488965E8GİEİ")
                        {
                            ClassVariable.IsFlash = true;
                            return true;
                        }
                    }
                    catch
                    {
                    }
                }
                ClassVariable.IsFlash = false;
                return false;
            }
        }

        bool Rsystm()
        {
            using (IEnumerator<DriveInfo> enumerator = (
                from u in (IEnumerable<DriveInfo>)DriveInfo.GetDrives()
                where u.DriveType == DriveType.Removable
                select u).GetEnumerator())
            {
                while (enumerator.MoveNext())
                {
                    DriveInfo current = enumerator.Current;
                    try
                    {
                        if (File.ReadAllText(string.Concat(current.RootDirectory, "rmove.txt")) == "uege32541kehİUFali_veli_hüseyin?İEHEJSTRİH52874TEMES548965E8GİEİ")
                            return true;
                    }
                    catch
                    {
                    }
                }
                return false;
            }
        }
        private void button2_Click(object sender, EventArgs e)
        {
            FormUptadePass yeni = new FormUptadePass();
            yeni.ShowDialog(this);
            yeni.Dispose();
        }

        private void label6_VisibleChanged(object sender, EventArgs e)
        {
        }

        private void bilgisayarıYenidenBaşlatToolStripMenuItem1_Click(object sender, EventArgs e)
        {
            LogSave("Bilgisayar Yeniden Başlatıldı " + Tarih, false);
            cls = true;
            ProcessStartInfo proc = new ProcessStartInfo();
            proc.WindowStyle = ProcessWindowStyle.Hidden;
            proc.FileName = "cmd";
            proc.Arguments = "/C shutdown -f -r -t 0";
            Process.Start(proc);
        }

        private void bilgisayarıYenidenBaşlatToolStripMenuItem_Click(object sender, EventArgs e)
        {
            LogSave("Bilgisayar Kapatıldı. " + Tarih, false);
            cls = true;
            Process.Start("shutdown", "/s /f /t 0");
        }

        private void ayarlarToolStripMenuItem_Click(object sender, EventArgs e)
        {

        }
        private void ekranKlavyesiniBaşlatToolStripMenuItem_Click(object sender, EventArgs e)
        {
            
            stms = false;
            FormEkranKlavyesi yeni = new FormEkranKlavyesi();
            yeni.ShowDialog(this);
            try
            {
                yeni.Dispose();
            }
            catch {; }
            stms = true;
        }

        void LockInit()
        {
            button1.Enabled = !button1.Enabled;
            contextMenuStrip1.Enabled = !contextMenuStrip1.Enabled;
        }
        private void pictureBox1_Click(object sender, EventArgs e)
        {
            this.TopMost = tmost;
        }
        private void textBox1_KeyPress(object sender, KeyPressEventArgs e)
        {
            if (e.KeyChar == Convert.ToChar(Keys.Enter))
                e.Handled = true;
        }
        private void Form1_KeyDown(object sender, KeyEventArgs e)
        {
            if (e.KeyCode == Keys.Control | e.KeyCode == Keys.K)
                textBox1.Visible = true;
        }
        private void textBox1_KeyDown(object sender, KeyEventArgs e)
        {
            if (tmost)
                return;
            if (e.KeyCode == Keys.Enter)
            {
                if (textBox1.Text == "_*:swf")
                {
                    startWork = false;
                    LockFree("Admin Açtı", false);
                    textBox1.Text = "_*:";
                }
                if (textBox1.Text == "_*:lf")
                {
                    LockFree("Admin Açtı", false);
                    textBox1.Text = "_*:";
                }
                if (textBox1.Text == "_*:sl")
                {
                    LockSystm("Admin Kapattı "+Tarih,false);
                    textBox1.Text = "_*:";
                }
                if (textBox1.Text == "_*:cs")
                {
                    label3.Text = "Sdwn:" + ClassClient.shutDown + "Tlck:" + ClassClient.TahtaLock + "Rmv:" + ClassClient.SystemRemove + "logS:" + ClassClient.LogSend;
                    textBox1.Text = "_*:";
                }
                if (textBox1.Text == "_*:is")
                {
                    label3.Text = ClassVariable.OPS.tn + "," + ClassVariable.OPS.t + "," + ClassVariable.OPS.k;
                    textBox1.Text = "_*:";
                }
                if (textBox1.Text == "_*:cls")
                {
                    kmtok = true;
                    textBox1.Visible = false;
                    startWork = true;
                    label3.Text = "[" + ClassVariable.Vercion + "] " + ClassVariable.OPS.tn;
                    textBox1.Text = "_*:";
                }
                if (textBox1.Text == "_*:srmv")
                {
                    Tools.RemoveSystm();
                    textBox1.Text = "_*:";
                }
                string[] val = textBox1.Text.Split(' ');
                if (val[0] == "_*:pass")
                {
                    if (val.Length == 2 && val[1] != "")
                        ClassVariable.OPS.p = val[2];
                    textBox1.Text = "_*:";
                }
                if (textBox1.Text == "_*:save")
                {
                    CheckFolder.SaveData();
                    textBox1.Text = "_*:";
                }
                if (textBox1.Text == "_*:aop")
                {
                    stms = false;
                    FormSettings yeni = new FormSettings();
                    yeni.ShowDialog(this);
                    textBox1.Text = "_*:";

                    stms = true;
                }
                if (textBox1.Text == "_*:opgy")
                {
                    kmtok = false;
                    foreach (ServiceController service in ServiceController.GetServices())
                    {
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
                    try
                    {
                        RegistryKey taskm2 = Registry.CurrentUser.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Policies\System", true);
                        taskm2.SetValue("DisableTaskMgr", 0);
                        taskm2.Close();
                    }
                    catch
                    {; }
                    textBox1.Text = "_*:";
                }
                textBox1.SelectionStart = textBox1.Text.Length;
            }
        }
    }
}
