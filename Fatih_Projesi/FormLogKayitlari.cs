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
    public partial class FormLogKayitlari : Form
    {
        public FormLogKayitlari()
        {
            InitializeComponent();
        }
        private void FormLogKayitlari_Load(object sender, EventArgs e)
        {
            if (File.Exists(@"C:\Logs\lgs1.txt"))
            {
                List<string> los = new List<string>();
                StreamReader streamReader = new StreamReader(@"C:\Logs\lgs1.txt");
                StreamReader sr = streamReader;
                string satir = "";
                while (true)
                {
                    satir = sr.ReadLine();
                    if (satir == null)
                        break;
                    if (satir != "")
                        los.Add(satir);
                }
                int sy = 1;
                for (int i = los.Count - 1; i >= 0; i--)
                {
                    richTextBox1.AppendText(sy + " : " + los[i] + "\n");
                    sy++;
                    Application.DoEvents();
                }
                richTextBox1.SelectionStart = 0;
            }
        }
    }
}
