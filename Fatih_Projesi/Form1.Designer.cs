namespace FatihProjesi
{
    partial class Form1
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
            this.components = new System.ComponentModel.Container();
            System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(Form1));
            this.button1 = new System.Windows.Forms.Button();
            this.label1 = new System.Windows.Forms.Label();
            this.contextMenuStrip1 = new System.Windows.Forms.ContextMenuStrip(this.components);
            this.girişÇıkışSaatleriToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.uygulamayıYenidenBaşlatToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.ekranKlavyesiniBaşlatToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.bilgisayarıYenidenBaşlatToolStripMenuItem1 = new System.Windows.Forms.ToolStripMenuItem();
            this.bilgisayarıYenidenBaşlatToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.adminMenüToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.komutPenceresiniAÇKAPATToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.sistemAyarlarıToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.sistemiKontrolEtToolStripMenuItem1 = new System.Windows.Forms.ToolStripMenuItem();
            this.logKayıtlarıToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.timer2 = new System.Windows.Forms.Timer(this.components);
            this.label2 = new System.Windows.Forms.Label();
            this.label3 = new System.Windows.Forms.Label();
            this.textBox1 = new System.Windows.Forms.TextBox();
            this.notifyIcon1 = new System.Windows.Forms.NotifyIcon(this.components);
            this.label6 = new System.Windows.Forms.Label();
            this.backgroundWorker1 = new System.ComponentModel.BackgroundWorker();
            this.backgroundWorker2 = new System.ComponentModel.BackgroundWorker();
            this.backgroundWorker3 = new System.ComponentModel.BackgroundWorker();
            this.button2 = new System.Windows.Forms.Button();
            this.pictureBox1 = new System.Windows.Forms.PictureBox();
            this.contextMenuStrip1.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.pictureBox1)).BeginInit();
            this.SuspendLayout();
            // 
            // button1
            // 
            this.button1.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right)));
            this.button1.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(128)))), ((int)(((byte)(255)))), ((int)(((byte)(128)))));
            this.button1.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.button1.Font = new System.Drawing.Font("Microsoft Sans Serif", 10F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(162)));
            this.button1.ForeColor = System.Drawing.Color.Blue;
            this.button1.Location = new System.Drawing.Point(1074, 7);
            this.button1.Name = "button1";
            this.button1.Size = new System.Drawing.Size(144, 29);
            this.button1.TabIndex = 0;
            this.button1.Text = "Tahtayı Aç";
            this.button1.UseVisualStyleBackColor = false;
            this.button1.Click += new System.EventHandler(this.button1_Click);
            // 
            // label1
            // 
            this.label1.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Right)));
            this.label1.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.label1.Font = new System.Drawing.Font("Algerian", 20F, ((System.Drawing.FontStyle)((System.Drawing.FontStyle.Bold | System.Drawing.FontStyle.Italic))), System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label1.ForeColor = System.Drawing.Color.Green;
            this.label1.Location = new System.Drawing.Point(1017, 415);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(200, 85);
            this.label1.TabIndex = 1;
            this.label1.Text = "00:00:00 00:00:00";
            this.label1.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            // 
            // contextMenuStrip1
            // 
            this.contextMenuStrip1.ImageScalingSize = new System.Drawing.Size(20, 20);
            this.contextMenuStrip1.Items.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.girişÇıkışSaatleriToolStripMenuItem,
            this.uygulamayıYenidenBaşlatToolStripMenuItem,
            this.ekranKlavyesiniBaşlatToolStripMenuItem,
            this.bilgisayarıYenidenBaşlatToolStripMenuItem1,
            this.bilgisayarıYenidenBaşlatToolStripMenuItem,
            this.adminMenüToolStripMenuItem});
            this.contextMenuStrip1.Name = "contextMenuStrip1";
            this.contextMenuStrip1.Size = new System.Drawing.Size(232, 136);
            // 
            // girişÇıkışSaatleriToolStripMenuItem
            // 
            this.girişÇıkışSaatleriToolStripMenuItem.Name = "girişÇıkışSaatleriToolStripMenuItem";
            this.girişÇıkışSaatleriToolStripMenuItem.Size = new System.Drawing.Size(231, 22);
            this.girişÇıkışSaatleriToolStripMenuItem.Text = "1 : Giriş Çıkış Saatleri";
            this.girişÇıkışSaatleriToolStripMenuItem.Click += new System.EventHandler(this.girişÇıkışSaatleriToolStripMenuItem_Click);
            // 
            // uygulamayıYenidenBaşlatToolStripMenuItem
            // 
            this.uygulamayıYenidenBaşlatToolStripMenuItem.Name = "uygulamayıYenidenBaşlatToolStripMenuItem";
            this.uygulamayıYenidenBaşlatToolStripMenuItem.Size = new System.Drawing.Size(231, 22);
            this.uygulamayıYenidenBaşlatToolStripMenuItem.Text = "2 : Uygulamayı Yeniden Başlat";
            this.uygulamayıYenidenBaşlatToolStripMenuItem.Click += new System.EventHandler(this.uygulamayıYenidenBaşlatToolStripMenuItem_Click);
            // 
            // ekranKlavyesiniBaşlatToolStripMenuItem
            // 
            this.ekranKlavyesiniBaşlatToolStripMenuItem.Name = "ekranKlavyesiniBaşlatToolStripMenuItem";
            this.ekranKlavyesiniBaşlatToolStripMenuItem.Size = new System.Drawing.Size(231, 22);
            this.ekranKlavyesiniBaşlatToolStripMenuItem.Text = "3 : Ekran Klavyesini Başlat";
            this.ekranKlavyesiniBaşlatToolStripMenuItem.Click += new System.EventHandler(this.ekranKlavyesiniBaşlatToolStripMenuItem_Click);
            // 
            // bilgisayarıYenidenBaşlatToolStripMenuItem1
            // 
            this.bilgisayarıYenidenBaşlatToolStripMenuItem1.Name = "bilgisayarıYenidenBaşlatToolStripMenuItem1";
            this.bilgisayarıYenidenBaşlatToolStripMenuItem1.Size = new System.Drawing.Size(231, 22);
            this.bilgisayarıYenidenBaşlatToolStripMenuItem1.Text = "4 : Bilgisayarı Yeniden Başlat";
            this.bilgisayarıYenidenBaşlatToolStripMenuItem1.Click += new System.EventHandler(this.bilgisayarıYenidenBaşlatToolStripMenuItem1_Click);
            // 
            // bilgisayarıYenidenBaşlatToolStripMenuItem
            // 
            this.bilgisayarıYenidenBaşlatToolStripMenuItem.Name = "bilgisayarıYenidenBaşlatToolStripMenuItem";
            this.bilgisayarıYenidenBaşlatToolStripMenuItem.Size = new System.Drawing.Size(231, 22);
            this.bilgisayarıYenidenBaşlatToolStripMenuItem.Text = "5 : Bilgisayarı Kapat";
            this.bilgisayarıYenidenBaşlatToolStripMenuItem.Click += new System.EventHandler(this.bilgisayarıYenidenBaşlatToolStripMenuItem_Click);
            // 
            // adminMenüToolStripMenuItem
            // 
            this.adminMenüToolStripMenuItem.DropDownItems.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.komutPenceresiniAÇKAPATToolStripMenuItem,
            this.sistemAyarlarıToolStripMenuItem,
            this.sistemiKontrolEtToolStripMenuItem1,
            this.logKayıtlarıToolStripMenuItem});
            this.adminMenüToolStripMenuItem.Name = "adminMenüToolStripMenuItem";
            this.adminMenüToolStripMenuItem.Size = new System.Drawing.Size(231, 22);
            this.adminMenüToolStripMenuItem.Text = "Admin Menü";
            // 
            // komutPenceresiniAÇKAPATToolStripMenuItem
            // 
            this.komutPenceresiniAÇKAPATToolStripMenuItem.Name = "komutPenceresiniAÇKAPATToolStripMenuItem";
            this.komutPenceresiniAÇKAPATToolStripMenuItem.Size = new System.Drawing.Size(244, 22);
            this.komutPenceresiniAÇKAPATToolStripMenuItem.Text = "a) Komut Penceresini AÇ/KAPAT";
            this.komutPenceresiniAÇKAPATToolStripMenuItem.Visible = false;
            this.komutPenceresiniAÇKAPATToolStripMenuItem.Click += new System.EventHandler(this.komutPenceresiniAÇKAPATToolStripMenuItem_Click);
            // 
            // sistemAyarlarıToolStripMenuItem
            // 
            this.sistemAyarlarıToolStripMenuItem.Name = "sistemAyarlarıToolStripMenuItem";
            this.sistemAyarlarıToolStripMenuItem.Size = new System.Drawing.Size(244, 22);
            this.sistemAyarlarıToolStripMenuItem.Text = "A) Sistem Ayarları";
            this.sistemAyarlarıToolStripMenuItem.Click += new System.EventHandler(this.sistemAyarlarıToolStripMenuItem_Click);
            // 
            // sistemiKontrolEtToolStripMenuItem1
            // 
            this.sistemiKontrolEtToolStripMenuItem1.Name = "sistemiKontrolEtToolStripMenuItem1";
            this.sistemiKontrolEtToolStripMenuItem1.Size = new System.Drawing.Size(244, 22);
            this.sistemiKontrolEtToolStripMenuItem1.Text = "B) Sistemi Kontrol Et";
            this.sistemiKontrolEtToolStripMenuItem1.Click += new System.EventHandler(this.sistemiKontrolEtToolStripMenuItem1_Click);
            // 
            // logKayıtlarıToolStripMenuItem
            // 
            this.logKayıtlarıToolStripMenuItem.Name = "logKayıtlarıToolStripMenuItem";
            this.logKayıtlarıToolStripMenuItem.Size = new System.Drawing.Size(244, 22);
            this.logKayıtlarıToolStripMenuItem.Text = "C) Log Kayıtları";
            this.logKayıtlarıToolStripMenuItem.Click += new System.EventHandler(this.logKayıtlarıToolStripMenuItem_Click);
            // 
            // timer2
            // 
            this.timer2.Interval = 1000;
            this.timer2.Tick += new System.EventHandler(this.timer2_Tick);
            // 
            // label2
            // 
            this.label2.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.label2.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(192)))), ((int)(((byte)(255)))), ((int)(((byte)(255)))));
            this.label2.Font = new System.Drawing.Font("Microsoft Sans Serif", 25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(162)));
            this.label2.Location = new System.Drawing.Point(0, 73);
            this.label2.Name = "label2";
            this.label2.Size = new System.Drawing.Size(1219, 338);
            this.label2.TabIndex = 6;
            this.label2.Text = "MESAJ BİLGİSİ";
            this.label2.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            this.label2.Visible = false;
            // 
            // label3
            // 
            this.label3.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right)));
            this.label3.BackColor = System.Drawing.Color.Teal;
            this.label3.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.label3.Font = new System.Drawing.Font("Agency FB", 10F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(162)));
            this.label3.Location = new System.Drawing.Point(511, 7);
            this.label3.Name = "label3";
            this.label3.Size = new System.Drawing.Size(197, 29);
            this.label3.TabIndex = 7;
            this.label3.Text = "Tahta İsmi : 9/A";
            this.label3.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            // 
            // textBox1
            // 
            this.textBox1.AcceptsReturn = true;
            this.textBox1.BackColor = System.Drawing.SystemColors.InfoText;
            this.textBox1.Font = new System.Drawing.Font("MS Reference Sans Serif", 12F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(162)));
            this.textBox1.ForeColor = System.Drawing.Color.Lime;
            this.textBox1.Location = new System.Drawing.Point(1, 1);
            this.textBox1.Multiline = true;
            this.textBox1.Name = "textBox1";
            this.textBox1.Size = new System.Drawing.Size(239, 52);
            this.textBox1.TabIndex = 8;
            this.textBox1.TabStop = false;
            this.textBox1.Visible = false;
            this.textBox1.KeyDown += new System.Windows.Forms.KeyEventHandler(this.textBox1_KeyDown);
            this.textBox1.KeyPress += new System.Windows.Forms.KeyPressEventHandler(this.textBox1_KeyPress);
            // 
            // notifyIcon1
            // 
            this.notifyIcon1.BalloonTipIcon = System.Windows.Forms.ToolTipIcon.Info;
            this.notifyIcon1.Icon = ((System.Drawing.Icon)(resources.GetObject("notifyIcon1.Icon")));
            this.notifyIcon1.Text = "mebre.com.tr";
            this.notifyIcon1.Visible = true;
            this.notifyIcon1.MouseDoubleClick += new System.Windows.Forms.MouseEventHandler(this.notifyIcon1_MouseDoubleClick);
            // 
            // label6
            // 
            this.label6.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right)));
            this.label6.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(255)))), ((int)(((byte)(128)))), ((int)(((byte)(128)))));
            this.label6.Font = new System.Drawing.Font("Microsoft Sans Serif", 8F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(162)));
            this.label6.ForeColor = System.Drawing.Color.Black;
            this.label6.Location = new System.Drawing.Point(756, 7);
            this.label6.Name = "label6";
            this.label6.Size = new System.Drawing.Size(310, 29);
            this.label6.TabIndex = 11;
            this.label6.Text = "Yeni Vesyion Bulundu V2.6 < V27";
            this.label6.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            this.label6.Visible = false;
            this.label6.VisibleChanged += new System.EventHandler(this.label6_VisibleChanged);
            // 
            // backgroundWorker1
            // 
            this.backgroundWorker1.WorkerSupportsCancellation = true;
            this.backgroundWorker1.DoWork += new System.ComponentModel.DoWorkEventHandler(this.backgroundWorker1_DoWork);
            // 
            // backgroundWorker2
            // 
            this.backgroundWorker2.WorkerSupportsCancellation = true;
            this.backgroundWorker2.DoWork += new System.ComponentModel.DoWorkEventHandler(this.backgroundWorker2_DoWork);
            // 
            // backgroundWorker3
            // 
            this.backgroundWorker3.WorkerSupportsCancellation = true;
            this.backgroundWorker3.DoWork += new System.ComponentModel.DoWorkEventHandler(this.backgroundWorker3_DoWork);
            // 
            // button2
            // 
            this.button2.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right)));
            this.button2.Location = new System.Drawing.Point(882, 38);
            this.button2.Name = "button2";
            this.button2.Size = new System.Drawing.Size(79, 23);
            this.button2.TabIndex = 12;
            this.button2.TabStop = false;
            this.button2.Text = "Güncelle";
            this.button2.UseVisualStyleBackColor = true;
            this.button2.Visible = false;
            this.button2.Click += new System.EventHandler(this.button2_Click);
            // 
            // pictureBox1
            // 
            this.pictureBox1.ContextMenuStrip = this.contextMenuStrip1;
            this.pictureBox1.Dock = System.Windows.Forms.DockStyle.Fill;
            this.pictureBox1.Image = global::FatihProjesi.Properties.Resources.Artboard_3;
            this.pictureBox1.Location = new System.Drawing.Point(0, 0);
            this.pictureBox1.Name = "pictureBox1";
            this.pictureBox1.Size = new System.Drawing.Size(1219, 501);
            this.pictureBox1.SizeMode = System.Windows.Forms.PictureBoxSizeMode.StretchImage;
            this.pictureBox1.TabIndex = 2;
            this.pictureBox1.TabStop = false;
            // 
            // Form1
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(1219, 501);
            this.ControlBox = false;
            this.Controls.Add(this.button2);
            this.Controls.Add(this.label6);
            this.Controls.Add(this.textBox1);
            this.Controls.Add(this.label3);
            this.Controls.Add(this.label2);
            this.Controls.Add(this.label1);
            this.Controls.Add(this.button1);
            this.Controls.Add(this.pictureBox1);
            this.DoubleBuffered = true;
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.None;
            this.Icon = ((System.Drawing.Icon)(resources.GetObject("$this.Icon")));
            this.KeyPreview = true;
            this.MaximizeBox = false;
            this.MinimizeBox = false;
            this.Name = "Form1";
            this.ShowIcon = false;
            this.ShowInTaskbar = false;
            this.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen;
            this.Text = "FATİH PROJESİ";
            this.TopMost = true;
            this.WindowState = System.Windows.Forms.FormWindowState.Maximized;
            this.Activated += new System.EventHandler(this.Form1_Activated);
            this.FormClosing += new System.Windows.Forms.FormClosingEventHandler(this.Form1_FormClosing);
            this.Load += new System.EventHandler(this.Form1_Load);
            this.KeyDown += new System.Windows.Forms.KeyEventHandler(this.Form1_KeyDown);
            this.Resize += new System.EventHandler(this.Form1_Resize);
            this.contextMenuStrip1.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.pictureBox1)).EndInit();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.Button button1;
        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.PictureBox pictureBox1;
        private System.Windows.Forms.Label label2;
        private System.Windows.Forms.Label label3;
        private System.Windows.Forms.TextBox textBox1;
        private System.Windows.Forms.ContextMenuStrip contextMenuStrip1;
        private System.Windows.Forms.NotifyIcon notifyIcon1;
        private System.Windows.Forms.Label label6;
        private System.ComponentModel.BackgroundWorker backgroundWorker1;
        private System.Windows.Forms.ToolStripMenuItem bilgisayarıYenidenBaşlatToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem bilgisayarıYenidenBaşlatToolStripMenuItem1;
        private System.ComponentModel.BackgroundWorker backgroundWorker2;
        private System.ComponentModel.BackgroundWorker backgroundWorker3;
        private System.Windows.Forms.ToolStripMenuItem ekranKlavyesiniBaşlatToolStripMenuItem;
        internal System.Windows.Forms.Timer timer2;
        private System.Windows.Forms.ToolStripMenuItem girişÇıkışSaatleriToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem uygulamayıYenidenBaşlatToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem adminMenüToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem komutPenceresiniAÇKAPATToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem sistemiKontrolEtToolStripMenuItem1;
        private System.Windows.Forms.ToolStripMenuItem sistemAyarlarıToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem logKayıtlarıToolStripMenuItem;
        private System.Windows.Forms.Button button2;
    }
}

