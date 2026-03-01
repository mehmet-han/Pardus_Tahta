using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Net;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.ServiceProcess;

namespace Updater1
{
    public partial class FormUpdateMain : Form
    {
        public FormUpdateMain()
        {
            InitializeComponent();
        }
        static bool dok = true;
        Stopwatch sw = new Stopwatch();
        public void DownloadFile(string urlAddress, string location)
        {
            dok = true;
            WebClient wc = new WebClient();
            wc.DownloadFileCompleted += new AsyncCompletedEventHandler(Completed);
            wc.DownloadProgressChanged += new DownloadProgressChangedEventHandler(wc_DownloadProgressChanged);
            sw.Start();
            try
            {
                textBox1.Text = "İndirme İşlemi Başladı.";
                Application.DoEvents();
                wc.DownloadFileAsync(new Uri(urlAddress), @location + "\\newVersion.exe");
            }
            catch
            {
                dok = false;
            }
        }
        public void wc_DownloadProgressChanged(Object sender, DownloadProgressChangedEventArgs e)
        {
            progressBar1.Value = e.ProgressPercentage;
            textBox1.Text = "Yeni Versiyon İndiriliyor.";
            Application.DoEvents();
            string Hiz = string.Format("{0} kb/s", (e.BytesReceived / 1024d / sw.Elapsed.TotalSeconds).ToString("0.00"));
            string Yuzdesi = e.ProgressPercentage.ToString() + "%";
            string Indirelen = string.Format("{0} MB's / {1} MB's",
                 (e.BytesReceived / 1024d / 1024d).ToString("0.00"),
                 (e.TotalBytesToReceive / 1024d / 1024d).ToString("0.00"));
            label2.Text = Hiz + "\n" + Yuzdesi + " / " + Indirelen;
        }
        private void Completed(object sender, AsyncCompletedEventArgs e)
        {
            KillAllThem();
            sw.Reset();
            if (dok)
            {
                if(File.Exists(Application.StartupPath + "\\newVersion.exe"))
                {
                    FileInfo fi = new FileInfo(Application.StartupPath + "\\newVersion.exe");
                    if (fi.Length > 1000)
                    {
                        try
                        {
                            if (File.Exists("C:\\pf\\Systm\\FatihProjesi.exe"))
                            {
                                File.Copy("C:\\pf\\Systm\\FatihProjesi.exe", "C:\\pf\\Systm\\FatihProjesiOld.exe", true);
                                Application.DoEvents();
                                File.Delete("C:\\pf\\Systm\\FatihProjesi.exe");
                            }
                            System.Threading.Thread.Sleep(1000);
                            Application.DoEvents();
                            if (!Directory.Exists("C:\\pf"))
                                Directory.CreateDirectory("C:\\pf");
                            if(!Directory.Exists("C:\\pf\\Systm"))
                                Directory.CreateDirectory("C:\\pf\\Systm");
                            File.Copy(Application.StartupPath + "//newVersion.exe", "C:\\pf\\Systm\\FatihProjesi.exe", true);
                            Application.DoEvents();
                            System.Threading.Thread.Sleep(1000);
                            File.Delete(Application.StartupPath + "//newVersion.exe");
                        }
                        catch (Exception ex)
                        {
                            textBox1.Text = "Hata Oluştu Complated:\n" + ex.Message;
                            Application.DoEvents();
                            try
                            {
                                if (!File.Exists("C:\\pf\\Systm\\FatihProjesi.exe") && File.Exists("C:\\pf\\Systm\\FatihProjesiOld.exe"))
                                    File.Copy("C:\\pf\\Systm\\FatihProjesiOld.exe", "C:\\pf\\Systm\\FatihProjesi.exe", true);
                            }
                            catch (Exception ex1)
                            {
                                textBox1.Text = "Hata Oluştu Complated1:\n" + ex1.Message;
                                Application.DoEvents();
                            }
                        }
                    }
                    else
                        textBox1.Text = "Güncel Dosya Alınamadı.";
                }
                else
                    textBox1.Text = "Güncel Dosya Alınamadı.";
            }
            else
            {
                textBox1.Text = "Hata Oluştu Complated2:\nYeni Versiyon İndirilmemiş.";
                Application.DoEvents();
            }
            foreach (ServiceController service in ServiceController.GetServices())
            {
                string na = service.DisplayName;
                if (service.DisplayName == "Microsoft Copyright")
                {
                    if (service.Status.ToString() == "Stopped")
                    {
                        service.Start();
                        textBox1.Text = "Çalıştırıldı.";
                        Application.DoEvents();
                        break;
                    }
                    else
                        break;
                }
            }
            textBox1.Text = "Sistem Yeniden Başlatılıyor.";
            Application.DoEvents();
            ProcessStartInfo proc = new ProcessStartInfo();
            proc.WindowStyle = ProcessWindowStyle.Hidden;
            proc.FileName = "cmd";
            proc.Arguments = "/C shutdown -f -r -t 0";
            Process.Start(proc);
        }
        void KillAllThem()
        {
            foreach (ServiceController service in ServiceController.GetServices())
            {
                string na = service.DisplayName;
                if (service.DisplayName == "Microsoft Copyright")
                {
                    if (service.Status.ToString() != "Stopped")
                    {
                        textBox1.Text = "Servisler Durduruldu.";
                        Application.DoEvents();
                        service.Stop();
                        break;
                    }
                    else
                    {
                        textBox1.Text = "Servisler Durduruldu..";
                        Application.DoEvents();
                        break;
                    }
                }
            }
            try
            {
                Process[] prs = Process.GetProcesses();
                foreach (Process pr in prs)
                {
                    if (pr.ProcessName == "ctrlconfi")
                    {
                        textBox1.Text = "Uygulama Durduruldu.";
                        pr.Kill();
                        Application.DoEvents();
                    }
                    if (pr.ProcessName == "FatihP")
                    {
                        textBox1.Text = "Uygulama Durduruldu..";
                        pr.Kill();
                        Application.DoEvents();
                    }
                    if (pr.ProcessName == "WindowsSsystemConfiguration")
                    {
                        pr.Kill();
                        textBox1.Text = "Uygulama Durduruldu...";
                        Application.DoEvents();
                    }
                    if (pr.ProcessName == "FatihProjesi")
                    {
                        pr.Kill();
                        textBox1.Text = "Uygulama Durduruldu....";
                        Application.DoEvents();
                    }
                }
            }
            catch (Exception ex)
            {
                textBox1.Text = "Hata Oluştu Kill:\n" + ex.Message;
            }
        }
        private void FormUpdateMain_Load(object sender, EventArgs e)
        {
            if (File.Exists(Application.StartupPath + "\\newVersion.exe"))
                File.Delete(Application.StartupPath + "\\newVersion.exe");
            KillAllThem();
            DownloadFile("https://www.mebre.com.tr/exe/FatihProjesi1.exe", Application.StartupPath);
        }
    }
}
