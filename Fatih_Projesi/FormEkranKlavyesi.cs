using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace FatihProjesi
{
    public partial class FormEkranKlavyesi : Form
    {
        public FormEkranKlavyesi()
        {
            InitializeComponent();
        }

        private void button5_Click(object sender, EventArgs e)
        {
            TastbarWindows.Show();
            Application.DoEvents();
            try
            {
                System.Diagnostics.Process.Start(@textBox7.Text);
                if (Properties.Settings.Default.pth != textBox7.Text && textBox7.Text != "")
                {
                    Properties.Settings.Default.pth = textBox7.Text;
                    Properties.Settings.Default.Save();
                }
            }
            catch (Exception ex)
            { MessageBox.Show(this,ex.Message); }
            TastbarWindows.Hide();
        }

        private void FormEkranKlavyesi_Load(object sender, EventArgs e)
        {
            textBox7.Text = Properties.Settings.Default.pth;
        }
    }
}
