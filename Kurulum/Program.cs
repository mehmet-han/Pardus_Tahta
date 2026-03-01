using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Principal;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace Kurulum
{
    static class Program
    {



        /// <summary>
        /// The main entry point for the application.
        /// </summary>
        [STAThread]
        static void Main()
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            bool IsAdmin = (new WindowsPrincipal(WindowsIdentity.GetCurrent()).IsInRole(WindowsBuiltInRole.Administrator));
            if (!IsAdmin)
            {
                MessageBox.Show("Lütfen Uygulamayı Yönetici Olarak Çalıştırınız.");
                Application.Exit();
            }
            else
                Application.Run(new FKurulum());
        }
    }
}
