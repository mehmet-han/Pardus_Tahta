using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Kurulum
{
    [Serializable]
    class opt
    {
        public string tn, kk, pass;
        public string[, ,] hours = new string[8, 19, 3];
    }
}
