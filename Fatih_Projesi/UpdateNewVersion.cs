using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.IO;
using System.Linq;
using System.Net;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace FatihProjesi
{
    class UpdateNewVersion
    {
        public static bool dok = true, IsComplete = false;
        public static string uneme = "";
        public static WebClient wc = new WebClient();
        public static void DownloadFile(string urlAddress, string location,string uexe)
        {
            uneme = uexe;
            IsComplete = false;
            dok = true;
            wc.DownloadFileCompleted += new AsyncCompletedEventHandler(Completed);
            wc.DownloadProgressChanged += new DownloadProgressChangedEventHandler(wc_DownloadProgressChanged);
            try
            {
                wc.DownloadFileAsync(new Uri(urlAddress), @location + "\\"+ uexe);
            }
            catch
            {
                dok = false;
            }
        }
        public static void wc_DownloadProgressChanged(Object sender, DownloadProgressChangedEventArgs e)
        {

        }
        private static void Completed(object sender, AsyncCompletedEventArgs e)
        {
            if (uneme == "Updater1.exe")
            {
                if (dok)
                {
                    if (File.Exists(Application.StartupPath + "\\"+ uneme))
                    {
                        IsComplete = true;
                    }
                    else
                    {
                        MessageBox.Show("İşlen Sırasında Hata Meydana Geldi..");
                    }
                }
                else
                {
                    MessageBox.Show("İşlen Sırasında Hata Meydana Geldi...");
                }
            }
        }
    }
}
