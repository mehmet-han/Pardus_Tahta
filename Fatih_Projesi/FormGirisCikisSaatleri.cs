using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Globalization;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace FatihProjesi
{
    public partial class FormGirisCikisSaatleri : Form
    {
        public FormGirisCikisSaatleri()
        {
            InitializeComponent();
        }
        int Ch = 1;
        int hn = 0;
        void SetAndChangeEvent()
        {
            //ClassVariable.OPS.hours[Ch, 1, 1] = txtg1.Text;
            //ClassVariable.OPS.hours[Ch, 1, 2] = txtc1.Text;
            //ClassVariable.OPS.hours[Ch, 2, 1] = txtg2.Text;
            //ClassVariable.OPS.hours[Ch, 2, 2] = txtc2.Text;
            //ClassVariable.OPS.hours[Ch, 3, 1] = txtg3.Text;
            //ClassVariable.OPS.hours[Ch, 3, 2] = txtc3.Text;
            //ClassVariable.OPS.hours[Ch, 4, 1] = txtg4.Text;
            //ClassVariable.OPS.hours[Ch, 4, 2] = txtc4.Text;
            //ClassVariable.OPS.hours[Ch, 5, 1] = txtg5.Text;
            //ClassVariable.OPS.hours[Ch, 5, 2] = txtc5.Text;
            //ClassVariable.OPS.hours[Ch, 6, 1] = txtg6.Text;
            //ClassVariable.OPS.hours[Ch, 6, 2] = txtc6.Text;
            //ClassVariable.OPS.hours[Ch, 7, 1] = txtg7.Text;
            //ClassVariable.OPS.hours[Ch, 7, 2] = txtc7.Text;
            //ClassVariable.OPS.hours[Ch, 8, 1] = txtg8.Text;
            //ClassVariable.OPS.hours[Ch, 8, 2] = txtc8.Text;
            //ClassVariable.OPS.hours[Ch, 9, 1] = txtg9.Text;
            //ClassVariable.OPS.hours[Ch, 9, 2] = txtc9.Text;
            //ClassVariable.OPS.hours[Ch, 10, 1] = txtg10.Text;
            //ClassVariable.OPS.hours[Ch, 10, 2] = txtc10.Text;
            //ClassVariable.OPS.hours[Ch, 11, 1] = txtg11.Text;
            //ClassVariable.OPS.hours[Ch, 11, 2] = txtc11.Text;
            //ClassVariable.OPS.hours[Ch, 12, 1] = txtg12.Text;
            //ClassVariable.OPS.hours[Ch, 12, 2] = txtc12.Text;
            //ClassVariable.OPS.hours[Ch, 13, 1] = txtg13.Text;
            //ClassVariable.OPS.hours[Ch, 13, 2] = txtc13.Text;
            //ClassVariable.OPS.hours[Ch, 14, 1] = txtg14.Text;
            //ClassVariable.OPS.hours[Ch, 14, 2] = txtc14.Text;
            //ClassVariable.OPS.hours[Ch, 15, 1] = txtg15.Text;
            //ClassVariable.OPS.hours[Ch, 15, 2] = txtc15.Text;
            //ClassVariable.OPS.hours[Ch, 16, 1] = txtg16.Text;
            //ClassVariable.OPS.hours[Ch, 16, 2] = txtc16.Text;
            //ClassVariable.OPS.hours[Ch, 17, 1] = txtg17.Text;
            //ClassVariable.OPS.hours[Ch, 17, 2] = txtc17.Text;
            //ClassVariable.OPS.hours[Ch, 18, 1] = txtg18.Text;
            //ClassVariable.OPS.hours[Ch, 18, 2] = txtc18.Text;
            if (radioButton1.Checked)
                Ch = 1;
            if (radioButton2.Checked)
                Ch = 2;
            if (radioButton3.Checked)
                Ch = 3;
            if (radioButton4.Checked)
                Ch = 4;
            if (radioButton5.Checked)
                Ch = 5;
            if (radioButton6.Checked)
                Ch = 6;
            if (radioButton7.Checked)
                Ch = 7;
            txtg1.Text = ClassVariable.OPS.hours[Ch, 1, 1];
            txtc1.Text = ClassVariable.OPS.hours[Ch, 1, 2];
            txtg2.Text = ClassVariable.OPS.hours[Ch, 2, 1];
            txtc2.Text = ClassVariable.OPS.hours[Ch, 2, 2];
            txtg3.Text = ClassVariable.OPS.hours[Ch, 3, 1];
            txtc3.Text = ClassVariable.OPS.hours[Ch, 3, 2];
            txtg4.Text = ClassVariable.OPS.hours[Ch, 4, 1];
            txtc4.Text = ClassVariable.OPS.hours[Ch, 4, 2];
            txtg5.Text = ClassVariable.OPS.hours[Ch, 5, 1];
            txtc5.Text = ClassVariable.OPS.hours[Ch, 5, 2];
            txtg6.Text = ClassVariable.OPS.hours[Ch, 6, 1];
            txtc6.Text = ClassVariable.OPS.hours[Ch, 6, 2];
            txtg7.Text = ClassVariable.OPS.hours[Ch, 7, 1];
            txtc7.Text = ClassVariable.OPS.hours[Ch, 7, 2];
            txtg8.Text = ClassVariable.OPS.hours[Ch, 8, 1];
            txtc8.Text = ClassVariable.OPS.hours[Ch, 8, 2];
            txtg9.Text = ClassVariable.OPS.hours[Ch, 9, 1];
            txtc9.Text = ClassVariable.OPS.hours[Ch, 9, 2];
            txtg10.Text = ClassVariable.OPS.hours[Ch, 10, 1];
            txtc10.Text = ClassVariable.OPS.hours[Ch, 10, 2];
            txtg11.Text = ClassVariable.OPS.hours[Ch, 11, 1];
            txtc11.Text = ClassVariable.OPS.hours[Ch, 11, 2];
            txtg12.Text = ClassVariable.OPS.hours[Ch, 12, 1];
            txtc12.Text = ClassVariable.OPS.hours[Ch, 12, 2];
            txtg13.Text = ClassVariable.OPS.hours[Ch, 13, 1];
            txtc13.Text = ClassVariable.OPS.hours[Ch, 13, 2];
            txtg14.Text = ClassVariable.OPS.hours[Ch, 14, 1];
            txtc14.Text = ClassVariable.OPS.hours[Ch, 14, 2];
            txtg15.Text = ClassVariable.OPS.hours[Ch, 15, 1];
            txtc15.Text = ClassVariable.OPS.hours[Ch, 15, 2];
            txtg16.Text = ClassVariable.OPS.hours[Ch, 16, 1];
            txtc16.Text = ClassVariable.OPS.hours[Ch, 16, 2];
            txtg17.Text = ClassVariable.OPS.hours[Ch, 17, 1];
            txtc17.Text = ClassVariable.OPS.hours[Ch, 17, 2];
            txtg18.Text = ClassVariable.OPS.hours[Ch, 18, 1];
            txtc18.Text = ClassVariable.OPS.hours[Ch, 18, 2];
        }
        private void FormGirisCikisSaatleri_Load(object sender, EventArgs e)
        {
            string GunuAl = CultureInfo.GetCultureInfo("tr-TR").DateTimeFormat.DayNames[(int)DateTime.Now.DayOfWeek];
            switch (GunuAl)
            {
                case "Pazartesi":
                    radioButton1.Checked = true;
                    break;
                case "Salı":
                    radioButton2.Checked = true;
                    break;
                case "Çarşamba":
                    radioButton3.Checked = true;
                    break;
                case "Perşembe":
                    radioButton4.Checked = true;
                    break;
                case "Cuma":
                    radioButton5.Checked = true;
                    break;
                case "Cumartesi":
                    radioButton6.Checked = true;
                    break;
                case "Pazar":
                    radioButton7.Checked = true;
                    break;
            }
            SetAndChangeEvent();
        }

        private void radioButton1_CheckedChanged(object sender, EventArgs e)
        {
            SetAndChangeEvent();
        }
    }
}
