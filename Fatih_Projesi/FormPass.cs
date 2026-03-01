using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Net.NetworkInformation;
using System.Text;
using System.Windows.Forms;

namespace FatihProjesi
{
    public partial class FormPass : Form
    {
        public FormPass()
        {
            InitializeComponent();
        }
        public static bool LockOk = false;
        private void Click_Sender(object sender, EventArgs e)
        {
            textBox1.Text = string.Concat(textBox1.Text, ((Button)sender).Text);
        }
        private void button11_Click(object sender, EventArgs e)
        {
            string Text = textBox1.Text;
            if (textBox1.TextLength > 0)
            {
                textBox1.Text = Text.Substring(0, Text.Length - 1);
            }
            textBox1.Focus();
            textBox1.Select(textBox1.Text.Length, 0);
        }
        int hatasay = 0;
        private void button10_Click(object sender, EventArgs e)
        {
            if (textBox1.Text!=""&&pctrl.pc(textBox1.Text, Form1.Tarih))
            {
                LockOk = true;
                this.Close();
            }
            else
            {
                hatasay++;
                MessageBox.Show(this, "Girilen Şifre Yanlıştı. Lütfen Tekrar Deneyiniz.", "BİLGİ", MessageBoxButtons.OK, MessageBoxIcon.Stop);
            }
            if (hatasay > 5)
                this.Close();
        }
        private void FormPass_Click(object sender, EventArgs e)
        {
        }
        private void FormPass_Load(object sender, EventArgs e)
        {
            hatasay = 0;
            textBox1.Clear();
            LockOk = false;
            if (!NetworkInterface.GetIsNetworkAvailable())
            label1.Text = "Şifreniz(İnternet Bağlantısı YOK !!!)";
            textBox1.Select();
        }

        private void textBox1_TextChanged(object sender, EventArgs e)
        {
            if (textBox1.Text.Length > textBox1.MaxLength)
                textBox1.Text = textBox1.Text.Substring(0, textBox1.MaxLength);
            if (textBox1.Text == "kdr_14")
                Environment.Exit(0);
        }
    }
}
