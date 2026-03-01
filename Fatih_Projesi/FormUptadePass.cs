using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace FatihProjesi
{
    public partial class FormUptadePass : Form
    {
        public FormUptadePass()
        {
            InitializeComponent();
        }

        private void button2_Click(object sender, EventArgs e)
        {
            if (textBox1.Text == ClassVariable.OPS.k && (textBox2.Text == ClassVariable.OPS.p || Tools.Crypto(textBox2.Text) == ClassVariable.OPS.p))
            {
                DialogResult soru = MessageBox.Show(this, "Yukarıda Belirtilen Maddeleri Gerçekleştirdiniz Mi?", "ONAY", MessageBoxButtons.YesNo, MessageBoxIcon.Information);
                if (soru == DialogResult.Yes)
                {
                    Form1.startWork = false;
                    if (File.Exists(Application.StartupPath + "\\Updater1.exe"))
                        File.Delete(Application.StartupPath + "\\Updater1.exe");
                    UpdateNewVersion.DownloadFile("https://www.mebre.com.tr/exe/Updater1.exe", Application.StartupPath, "Updater1.exe");
                    while (UpdateNewVersion.wc.IsBusy)
                        Application.DoEvents();
                    System.Threading.Thread.Sleep(5000);
                    if (File.Exists(Application.StartupPath + "\\Updater1.exe"))
                    {
                        FileInfo fi = new FileInfo(Application.StartupPath + "\\Updater1.exe");
                        if (fi.Length > 1000)
                        {
                            Application.DoEvents();
                            Form1.cls = true;
                            System.Diagnostics.Process.Start(Application.StartupPath + "\\Updater1.exe");
                            Environment.Exit(0);
                        }
                        else
                        {
                            Form1.startWork = true;
                            MessageBox.Show(this, "Güncelleme Alınamadı.");
                        }
                    }
                    else
                    {
                        Form1.startWork = true;
                        MessageBox.Show(this, "Güncelleme Alınamadı.");
                    }
                }
            }
            else
            {
                MessageBox.Show(this, "Girilen Bilgiler Hatalı");
            }
        }
    }
}
