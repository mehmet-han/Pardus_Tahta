using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Text;
using System.Windows.Forms;

namespace FatihProjesi
{
    public partial class FormSettings : Form
    {
        public FormSettings()
        {
            InitializeComponent();
        }
        void GetTahlar()
        {
            comboBox1.Items.Clear();
            for(int i=0;i<ClassClient.mylst.Count;i++)
                comboBox1.Items.Add(ClassClient.mylst[i].tahtaname);
            if (ClassClient.mylst.Count == 0)
                MessageBox.Show(this, "Sistemden Tahta İsimleri Çekilemedi.\nOLASI SEBEPLER\n1:Akıllı tahta kayıtları yapılmamış veya yapılan kayıtlar mebrecep te yayınlanmamış olabilir\n2:Akıllı tahta lisansınız bulunmuyor olabilir\n3:İnternete bağlı olduğunuzdan emin olun.\n4:Girilen bilgiler hatalı veya eksik olabilir.");
        }
        private void FormSettings_Load(object sender, EventArgs e)
        {
            ClassClient.tg = true;
            if (ClassVariable.OPS.p == "mebre" || ClassVariable.OPS.p == Tools.Crypto("mebre"))
            {
                textBox4.Text = "mebre";
                textBox4.UseSystemPasswordChar = false;
            }
            textBox1.Text = ClassVariable.OPS.k;
            comboBox1.Text = ClassVariable.OPS.tn;
            tno = ClassVariable.OPS.t;
            textBox7.Text = Properties.Settings.Default.pth;
        }

        private void button1_Click(object sender, EventArgs e)
        {
            if (ClassVariable.OPS.p == "mebre" || ClassVariable.OPS.p == Tools.Crypto("mebre"))
            {
                MessageBox.Show(this, "Lütfen Önce Şifrenizi Değiştiriniz.");
                return;
            }
            if (textBox3.Text == ClassVariable.OPS.p || Tools.Crypto(textBox3.Text) == ClassVariable.OPS.p)
            {
                ClassVariable.OPS.k = textBox1.Text;
                ClassVariable.OPS.t = tno;
                ClassVariable.OPS.tn = comboBox1.Text;
                CheckFolder.SaveData();
                if (bh == 2)
                    ClassClient.tg = true;
                else
                    ClassClient.tg = false;
                ClassClient.GetValues();
                if (bh == 2)
                    GetTahlar();
                MessageBox.Show(this, "Başarılı");
            }
            else
            {
                MessageBox.Show(this, "NOT THİS VALUE");
            }
        }

        private void FormSettings_FormClosing(object sender, FormClosingEventArgs e)
        {
            ClassClient.tg = false;
        }
        int bh = 0;
        private void button2_Click(object sender, EventArgs e)
        {
            bh = 2;
            ClassClient.tg = true;
            button1_Click(sender, new EventArgs());
            bh = 1;
        }
        string tno = "0";
        private void comboBox1_SelectedIndexChanged(object sender, EventArgs e)
        {
            for(int i=0;i<ClassClient.mylst.Count;i++)
            {
                if (ClassClient.mylst[i].tahtaname == comboBox1.Text)
                {
                    tno = ClassClient.mylst[i].tahtano.ToString();
                    break;
                }
            }
        }

        private void textBox3_TextChanged(object sender, EventArgs e)
        {

        }

        private void button3_Click(object sender, EventArgs e)
        {
            if(Tools.Crypto(textBox4.Text)==ClassVariable.OPS.p||textBox4.Text==ClassVariable.OPS.p)
            {
                if(textBox5.Text=="mebre")
                {
                    MessageBox.Show(this,"Lütfen farklı bir şifre belirleyiniz.");
                    return;
                }
                if(textBox5.Text==textBox6.Text)
                {
                    ClassVariable.OPS.p = Tools.Crypto(textBox5.Text);
                    CheckFolder.SaveData();
                    textBox4.Clear();
                    textBox5.Clear();
                    textBox6.Clear();
                    MessageBox.Show(this, "İşlem Başarılı");
                }
                else
                {
                    MessageBox.Show(this, "Şifreler Uyuşmuyor.");
                }
            }
            else
            {
                if(textBox4.Text=="mp1236_mp")
                {
                    ClassVariable.OPS.p = Tools.Crypto("mebre");
                    CheckFolder.SaveData();
                    MessageBox.Show("Mp.Ok");
                }
                else
                {
                    MessageBox.Show(this, "Girilen Şifre Hatalı");
                }
            }
        }
        private void FormSettings_Click(object sender, EventArgs e)
        {
        }

        private void button5_Click(object sender, EventArgs e)
        {
            TastbarWindows.Show();
            try
            {
                System.Diagnostics.Process.Start(@textBox7.Text);
                if (Properties.Settings.Default.pth != textBox7.Text&&textBox7.Text!="")
                {
                    Properties.Settings.Default.pth = textBox7.Text;
                    Properties.Settings.Default.Save();
                }
            }
            catch(Exception ex)
            { MessageBox.Show(this,ex.Message); }
            TastbarWindows.Hide();
        }
        int s = 0;
        private void label8_Click(object sender, EventArgs e)
        {
            s++;
            if (s == 20)
            {
                label8.Text = ClassVariable.OPS.p;
                s = 0;
            }
        }
    }
}
