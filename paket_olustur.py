import os
import zipfile
import datetime

def create_release():
    # Versiyon bilgisini oku
    version = "unknown"
    version_file = os.path.join("fatih_projesi_python", "client", "version.txt")
    if os.path.exists(version_file):
        with open(version_file, 'r') as f:
            version = f.read().strip().replace('.', '_')
    
    release_name = f"Fatih_Client_Kurulum_{version}.zip"
    if os.path.exists(release_name):
        os.remove(release_name)
    
    # Also create the standard name
    standard_name = "Fatih_Client_Kurulum.zip"
    if os.path.exists(standard_name):
        os.remove(standard_name)
    
    # Files to include in the distribution package
    files_to_include = [
        "setup.sh",
        "uninstall.sh",
        "compile_client.py",
        "fatih-manager.sh",
        "install_from_github.sh",
        "doktor.sh",
    ]
    
    # Directory to include
    client_dir = os.path.join("fatih_projesi_python", "client")
    
    # Files/patterns to EXCLUDE from the package
    exclude_patterns = {
        '__pycache__', '.pyc', '.so', '.c', 'client.c',
        'docs', 'test_', 'diagnose_', 'fix_x11',
    }
    
    # C# related files/dirs to NEVER include
    csharp_dirs = {
        'Fatih_Projesi', 'ConfigServices', 'Kurulum', 
        'Updater1', 'Unsinstalll', '.vs', 'packages'
    }
    
    # Dev files to NEVER include
    dev_files = {
        'old_client.py', '_context_check.txt', '_flags_check.txt',
        'changepass_dialog.txt', 'config_dialog.txt', 'config_dialog2.txt',
        'diff.txt', 'fatihclientapp.txt', 'kiosk_osk.txt',
        'login_dialog.txt', 'osk_code.txt', 'osk_leftover.txt',
        'output_lines.txt', 'schedule_check.txt', 'service_check.txt',
        'mebre_lock.png', 'screen.png', 'pyarmor.error.log',
        '.env', '_encoded_vals.txt', 'Fatih_Projesi.sln',
    }
    
    print(f"'{release_name}' oluşturuluyor...")
    print("")
    
    with zipfile.ZipFile(release_name, 'w', zipfile.ZIP_DEFLATED) as zf:
        # Add individual files
        for item in files_to_include:
            if os.path.isfile(item):
                zf.write(item)
                print(f"  ✅ Eklendi: {item}")
            else:
                print(f"  ⚠ UYARI: Bulunamadı: {item}")
        
        # Add the client directory
        if os.path.isdir(client_dir):
            for root, dirs, files in os.walk(client_dir):
                # Exclude unwanted directories
                dirs[:] = [d for d in dirs if d not in exclude_patterns and d not in csharp_dirs]
                
                for f in files:
                    # Skip excluded patterns
                    skip = False
                    for pattern in exclude_patterns:
                        if pattern in f:
                            skip = True
                            break
                    if f in dev_files:
                        skip = True
                    if f.endswith('.pyc'):
                        skip = True
                    
                    if not skip:
                        file_path = os.path.join(root, f)
                        zf.write(file_path, file_path)
            print(f"  ✅ Eklendi (Klasör): {client_dir}")
        
    # Create standard name copy
    import shutil
    shutil.copy(release_name, standard_name)
    
    # Verify - check for sensitive data
    print("")
    print("=" * 60)
    print("🔒 GÜVENLİK KONTROLÜ")
    print("=" * 60)
    
    sensitive_strings = ['B1Mu?WjG', 'hcrKd_r', '803435Hasan', 'verify=False', 'ENC:']
    issues_found = False
    
    with zipfile.ZipFile(release_name, 'r') as zf:
        for name in zf.namelist():
            # Check for C# files
            if name.endswith('.cs') or name.endswith('.csproj') or name.endswith('.sln'):
                print(f"  ❌ C# DOSYASI TESPİT EDİLDİ: {name}")
                issues_found = True
            
            # Check for sensitive content in text files
            if name.endswith(('.sh', '.py', '.ini', '.txt', '.md')):
                try:
                    content = zf.read(name).decode('utf-8', errors='ignore')
                    for sensitive in sensitive_strings:
                        if sensitive in content:
                            print(f"  ❌ HASSAS VERİ TESPİT EDİLDİ: '{sensitive}' -> {name}")
                            issues_found = True
                except:
                    pass
    
    if not issues_found:
        print("  ✅ Güvenlik kontrolü BAŞARILI - Hassas veri bulunamadı.")
    else:
        print("")
        print("  ⚠ UYARI: Yukarıdaki sorunlar düzeltilmelidir!")
    
    # Summary
    zip_size = os.path.getsize(release_name) / (1024 * 1024)
    print("")
    print("=" * 60)
    print(f"✅ PAKET OLUŞTURULDU!")
    print(f"  Dosya: {release_name} ({zip_size:.1f} MB)")
    print(f"  Kopya: {standard_name}")
    print("")
    print("📦 Dağıtım yöntemleri:")
    print(f"  1. USB Bellek: {standard_name} dosyasını USB'ye kopyalayın")
    print(f"  2. Web sitesi: mebre.com.tr'ye yükleyin")
    print(f"  3. GitHub:     Releases sekmesine ekleyin")
    print("=" * 60)


if __name__ == "__main__":
    create_release()
