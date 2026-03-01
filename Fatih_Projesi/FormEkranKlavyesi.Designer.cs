
namespace FatihProjesi
{
    partial class FormEkranKlavyesi
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(FormEkranKlavyesi));
            this.label10 = new System.Windows.Forms.Label();
            this.textBox7 = new System.Windows.Forms.TextBox();
            this.button5 = new System.Windows.Forms.Button();
            this.label1 = new System.Windows.Forms.Label();
            this.SuspendLayout();
            // 
            // label10
            // 
            this.label10.AutoSize = true;
            this.label10.Location = new System.Drawing.Point(70, 18);
            this.label10.Name = "label10";
            this.label10.Size = new System.Drawing.Size(63, 13);
            this.label10.TabIndex = 26;
            this.label10.Text = "Klavye Yolu";
            // 
            // textBox7
            // 
            this.textBox7.Location = new System.Drawing.Point(12, 34);
            this.textBox7.Name = "textBox7";
            this.textBox7.Size = new System.Drawing.Size(263, 20);
            this.textBox7.TabIndex = 25;
            this.textBox7.Text = "C:\\WINDOWS\\system32\\osk.exe";
            // 
            // button5
            // 
            this.button5.Location = new System.Drawing.Point(281, 32);
            this.button5.Name = "button5";
            this.button5.Size = new System.Drawing.Size(126, 25);
            this.button5.TabIndex = 24;
            this.button5.TabStop = false;
            this.button5.Text = "Ekran Klavyesini Aç";
            this.button5.UseVisualStyleBackColor = true;
            this.button5.Click += new System.EventHandler(this.button5_Click);
            // 
            // label1
            // 
            this.label1.BackColor = System.Drawing.SystemColors.Control;
            this.label1.ForeColor = System.Drawing.Color.FromArgb(((int)(((byte)(192)))), ((int)(((byte)(0)))), ((int)(((byte)(0)))));
            this.label1.Location = new System.Drawing.Point(9, 77);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(406, 43);
            this.label1.TabIndex = 27;
            this.label1.Text = "Not : Ekran klavyeleri her Pc de aynı  konumda olmayabilir. Böyle bir durumda dos" +
    "ya yolunu değiştirerek işleme devam edebilirsiniz.";
            // 
            // FormEkranKlavyesi
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(427, 118);
            this.Controls.Add(this.label1);
            this.Controls.Add(this.label10);
            this.Controls.Add(this.textBox7);
            this.Controls.Add(this.button5);
            this.Icon = ((System.Drawing.Icon)(resources.GetObject("$this.Icon")));
            this.MaximizeBox = false;
            this.MaximumSize = new System.Drawing.Size(443, 157);
            this.MinimizeBox = false;
            this.MinimumSize = new System.Drawing.Size(443, 157);
            this.Name = "FormEkranKlavyesi";
            this.ShowIcon = false;
            this.ShowInTaskbar = false;
            this.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen;
            this.Text = "Ekran Klavyesi";
            this.Load += new System.EventHandler(this.FormEkranKlavyesi_Load);
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.Label label10;
        private System.Windows.Forms.TextBox textBox7;
        private System.Windows.Forms.Button button5;
        private System.Windows.Forms.Label label1;
    }
}