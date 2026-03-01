using System;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Net.NetworkInformation;
using System.Threading;
using System.Windows.Forms;

namespace FatihProjesi
{
    static class FatihP
    {
        /// <summary>
        /// The main entry point for the application.
        /// </summary>
        /// 
       static Mutex mutex;
        static bool ctrl;
        [STAThread]
        static void Main()
        {
            if (File.Exists(ClassVariable.SilmeDosyasiYolu))
                Environment.Exit(0);

            if (!File.Exists(Application.StartupPath + "\\Newtonsoft.Json.dll"))
            {
                if (NetworkInterface.GetIsNetworkAvailable())
                {
                    try
                    {
                        using (WebClient wc = new WebClient())
                        {
                            wc.DownloadFile(new Uri("https://www.mebre.com.tr/exe/Newtonsoft.Json.dll"), Application.StartupPath + "\\Newtonsoft.Json.dll");
                        }
                    }
                    catch {; }
                }
            }

            mutex = new Mutex(true, "FatihP", out ctrl);
            if (ctrl)
            {
                Application.EnableVisualStyles();
                Application.SetCompatibleTextRenderingDefault(false);
                if (!System.Diagnostics.Debugger.IsAttached)
                {
                    Application.SetUnhandledExceptionMode(UnhandledExceptionMode.CatchException);
                    Application.ThreadException += Application_ThreadException;
                    AppDomain.CurrentDomain.UnhandledException += CurrentDomain_UnhandledException;
                }
                Application.Run(new Form1());
            }
            else
                Application.Exit();
        }

        private static void CurrentDomain_UnhandledException(object sender, UnhandledExceptionEventArgs e)
        {
            var sm = DateTime.Now.ToLongTimeString() + "\n\n<Unhandled Excpetion>\n\nObject: " + e.ExceptionObject + "\n\nIsTerminating: " + e.IsTerminating + "";
            ClassClient.LogSave(sm, "Programcsnin icinde CurrentDomain_UnhandledException"); 
            Application.Restart();
        }
        private static void Application_ThreadException(object sender, System.Threading.ThreadExceptionEventArgs e)
        {
            var data = "";
            foreach (var v in e.Exception.Data)
                data += v.ToString() + "\n";
            var sm = "Thread Exception:" + e.Exception.ToString() + "\n\nKonum:" + e.Exception.Source + "\n\nHata:" + e.Exception.InnerException + "\n\nData:" + data;
            ClassClient.LogSave(sm, "Programcsnin icinde CurrentDomain_UnhandledException");
            Application.Restart();
        }
    }
}
