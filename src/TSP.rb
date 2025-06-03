require 'set'

# Fungsi untuk membaca matriks jarak dari file
def readfile(path_file)
  begin
    file = File.open(path_file)
    baris_baris = file.readlines.map(&:chomp)
    jumlah_kota = baris_baris.size # Ukuran matriks (jumlah kota)

    matriks_jarak = Array.new(jumlah_kota) { Array.new(jumlah_kota, Float::INFINITY) }

    baris_baris.each_with_index do |baris, i|
      nilai_baris = baris.split.map { |x| x.downcase == "infinity" ? Float::INFINITY : x.to_f }

      if nilai_baris.size != jumlah_kota
        puts "Error: Baris #{i + 1} ('#{baris}') memiliki #{nilai_baris.size} kolom, seharusnya #{jumlah_kota}."
        return nil, nil 
      end
      matriks_jarak[i] = nilai_baris
    end
    [jumlah_kota, matriks_jarak]
  rescue Errno::ENOENT 
    puts "Error: File '#{path_file}' tidak ditemukan."
    return nil, nil 
  rescue StandardError => e 
    puts "Error saat membaca file '#{path_file}': #{e.message}"
    return nil, nil 
  end
end

# Menghitung biaya minimum dan menyimpan 'langkah_berikutnya' untuk rekonstruksi jalur.
def calculate_tsp_detail(idx_kota_sekarang, set_kota_tersisa, matriks_jarak, memo, idx_kota_awal)
  if set_kota_tersisa.empty?
    biaya_kembali = matriks_jarak[idx_kota_sekarang][idx_kota_awal]
    return { biaya: biaya_kembali, langkah_berikutnya: idx_kota_awal }
  end

  state_key = [idx_kota_sekarang, set_kota_tersisa]
  return memo[state_key] if memo.key?(state_key)

  total_biaya_minimum = Float::INFINITY
  langkah_terbaik_berikutnya = nil 

  set_kota_tersisa.each do |kandidat_kota_berikutnya|
    biaya_ke_kandidat = matriks_jarak[idx_kota_sekarang][kandidat_kota_berikutnya]

    next if biaya_ke_kandidat == Float::INFINITY

    set_sisa_baru = set_kota_tersisa.dup
    set_sisa_baru.delete(kandidat_kota_berikutnya)

    detail_sub_masalah = calculate_tsp_detail(
      kandidat_kota_berikutnya,
      set_sisa_baru,
      matriks_jarak,
      memo,
      idx_kota_awal
    )

    if detail_sub_masalah[:biaya] != Float::INFINITY
      total_biaya_jalur_sekarang = biaya_ke_kandidat + detail_sub_masalah[:biaya]

      if total_biaya_jalur_sekarang < total_biaya_minimum
        total_biaya_minimum = total_biaya_jalur_sekarang
        langkah_terbaik_berikutnya = kandidat_kota_berikutnya
      end
    end
  end
  
  hasil = { biaya: total_biaya_minimum, langkah_berikutnya: langkah_terbaik_berikutnya }
  memo[state_key] = hasil
  hasil
end

# Fungsi untuk merekonstruksi jalur TSP optimal dari tabel memoization.
def rekonstruksi_jalur_dari_memo(idx_kota_awal, jumlah_kota, memo)
  jalur = [idx_kota_awal]
  kota_sekarang = idx_kota_awal

  set_sisa_sekarang = Set.new((0...jumlah_kota).to_a)
  set_sisa_sekarang.delete(idx_kota_awal) # Hapus kota awal dari set ini

  (jumlah_kota - 1).times do
    state_key = [kota_sekarang, set_sisa_sekarang]
    entri_memo = memo[state_key]

    if entri_memo.nil? || entri_memo[:langkah_berikutnya].nil?
      puts "Error internal: Gagal merekonstruksi jalur. Entri memo tidak ditemukan atau tidak valid untuk state #{state_key}."
      return nil 
    end

    kota_berikutnya_dalam_jalur = entri_memo[:langkah_berikutnya]
    jalur.push(kota_berikutnya_dalam_jalur)

    set_sisa_sekarang.delete(kota_berikutnya_dalam_jalur) if set_sisa_sekarang.member?(kota_berikutnya_dalam_jalur)
    kota_sekarang = kota_berikutnya_dalam_jalur
  end

  jalur.push(idx_kota_awal)
  jalur
end

# --- Bagian Utama Program ---
puts <<-'JUDUL'
===============================================================
  Program Dinamis untuk Traveling Salesperson Problem (TSP)
                13523041 - Hanif Kalyana Aditya
===============================================================
JUDUL

puts "Masukkan nama file yang berisi matriks jarak (contoh: data_tsp.txt):"
nama_file = gets.chomp
# Asumsikan file berada di direktori yang sama 
path_file_lengkap = File.expand_path(nama_file)

jumlah_kota, matriks_jarak = readfile(path_file_lengkap)

exit unless jumlah_kota && matriks_jarak

if jumlah_kota == 0
  puts "Tidak ada kota yang ditemukan dalam file input. Program berhenti."
  exit
end

puts "\nMatriks Jarak yang Dibaca (Kota 1 s/d #{jumlah_kota}):"
matriks_jarak.each_with_index do |baris, idx_baris|
  print "Kota #{idx_baris + 1}: [ "
  puts baris.map { |val| val == Float::INFINITY ? 'inf' : val.to_s }.join(', ') + " ]"
end
puts "---------------------------------------------------------------"

idx_kota_awal_input = -1
loop do
  puts "Masukkan nomor kota awal (antara 1 sampai #{jumlah_kota}):"
  input_pengguna = gets.chomp
  if input_pengguna.match?(/^\d+$/) && input_pengguna.to_i.between?(1, jumlah_kota)
    idx_kota_awal_input = input_pengguna.to_i
    break 
  else
    puts "Input tidak valid. Harap masukkan angka antara 1 dan #{jumlah_kota}."
  end
end

idx_kota_awal_internal = idx_kota_awal_input - 1

memo = {}

set_awal_kota_tersisa = Set.new((0...jumlah_kota).to_a) 
set_awal_kota_tersisa.delete(idx_kota_awal_internal)

# Kasus khusus jika hanya ada satu kota.
detail_solusi = if jumlah_kota == 1
                  # Jika hanya satu kota, biaya adalah dari kota itu ke dirinya sendiri (biasanya 0 atau nilai diagonal).
                  biaya_satu_kota = (matriks_jarak[0] && matriks_jarak[0][0]) ? matriks_jarak[0][0] : 0
                  biaya_satu_kota = 0 if biaya_satu_kota == Float::INFINITY # Anggap 0 jika tak hingga
                  { biaya: biaya_satu_kota, langkah_berikutnya: idx_kota_awal_internal }
                else
                  calculate_tsp_detail(idx_kota_awal_internal, set_awal_kota_tersisa, matriks_jarak, memo, idx_kota_awal_internal)
                end

biaya_minimum = detail_solusi[:biaya]

puts "---------------------------------------------------------------"
if biaya_minimum == Float::INFINITY || biaya_minimum.nil?
  puts "Tidak ditemukan jalur TSP yang valid."
  puts "Ini bisa terjadi jika graf tidak terhubung sepenuhnya atau tidak ada cara untuk kembali ke kota awal."
else
  # Rekonstruksi jalur optimal
  indeks_rute = if jumlah_kota == 1
                  [idx_kota_awal_internal, idx_kota_awal_internal]
                else
                  rekonstruksi_jalur_dari_memo(idx_kota_awal_internal, jumlah_kota, memo)
                end

  if indeks_rute
    rute_tampilan = indeks_rute.map { |x| x + 1 }
    puts "Jalur TSP paling optimal yang ditemukan adalah:"
    puts "  [ #{rute_tampilan.join(' -> ')} ]"
    puts "Dengan total biaya: #{biaya_minimum}"
  else
    puts "Terjadi kesalahan saat merekonstruksi jalur, meskipun biaya minimum ditemukan."
    puts "Biaya minimum: #{biaya_minimum}"
  end
end
puts "==============================================================="

