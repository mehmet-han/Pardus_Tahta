import os
import zipfile

def create_release():
    release_name = "Fatih_Client_Kurulum.zip"
    if os.path.exists(release_name):
        os.remove(release_name)
        
    # The essential files for Fatih Client installation
    files_to_include = [
        "setup.sh",
        "uninstall.sh",
        "compile_client.py",
        "fatih_projesi_python"
    ]
    
    print(f"'{release_name}' oluşturuluyor...")
    
    with zipfile.ZipFile(release_name, 'w', zipfile.ZIP_DEFLATED) as zf:
        for item in files_to_include:
            if os.path.isfile(item):
                zf.write(item)
                print(f"Eklendi: {item}")
            elif os.path.isdir(item):
                for root, dirs, files in os.walk(item):
                    # Exclude the __pycache__ folders to keep it clean
                    if '__pycache__' in dirs:
                        dirs.remove('__pycache__')
                    for f in files:
                        # Skip compiled files if they exist locally
                        if not f.endswith('.pyc') and not f.endswith('.so'):
                            file_path = os.path.join(root, f)
                            zf.write(file_path, file_path)
                print(f"Eklendi (Klasör): {item}")
            else:
                print(f"UYARI: Bulunamadı: {item}")
                            
    print("\n" + "="*50)
    print("✅ BAŞARILI!")
    print(f"Sadece kurulum için gerekli olan '{release_name}' dosyası oluşturuldu.")
    print("Müşterilere veya tahtalara SADECE bu ZIP dosyasını götürün/gönderin.")
    print("C# kaynak kodlarınız (Fatih_Projesi dizini) bu pakete dahil EDİLMEMİŞTİR!")
    print("="*50)

if __name__ == "__main__":
    create_release()
