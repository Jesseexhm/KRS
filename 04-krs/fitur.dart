import 'data.dart';
import 'input.dart';

// ============================================================
// Fungsi bantu
// ============================================================

/// Mencari mata kuliah berdasarkan kode. Mengembalikan null jika tidak ada.
Map<String, dynamic>? cariByKode(String kode) {
  for (final matkul in daftarMatkul) {
    if (matkul['kode'] == kode) return matkul;
  }
  return null;
}

/// Mencetak satu baris data mata kuliah.
void cetakMatkul(Map<String, dynamic> matkul) {
  final hari = matkul['hari'] as Hari;
  print(
    '${matkul['kode']} | ${matkul['nama']} | ${matkul['sks']} SKS | '
    '${hari.name} ${matkul['mulai']}-${matkul['selesai']}',
  );
}

/// Menjumlahkan SKS semua mata kuliah di KRS.
int hitungTotalSks() {
  var total = 0;
  for (final kode in krs) {
    total += cariByKode(kode)!['sks'] as int;
  }
  return total;
}

/// Meminta pengguna memilih hari.
Hari bacaHari() {
  final pilihan = bacaInt(
    'Hari (1=senin, 2=selasa, 3=rabu, 4=kamis, 5=jumat)',
    min: 1,
    max: 5,
  );
  return switch (pilihan) {
    1 => Hari.senin,
    2 => Hari.selasa,
    3 => Hari.rabu,
    4 => Hari.kamis,
    _ => Hari.jumat,
  };
}

// ============================================================
// Fitur yang sudah jadi
// ============================================================

/// Menu 1: menampilkan semua mata kuliah yang ditawarkan.
void tampilkanMatkul() {
  print('\n=== Mata Kuliah Ditawarkan ===');
  for (final matkul in daftarMatkul) {
    cetakMatkul(matkul);
  }
}

/// Menu 2: mengambil mata kuliah ke KRS.
void ambilMatkul() {
  print('\n=== Ambil Mata Kuliah ===');
  final kode = bacaTeks('Kode mata kuliah').toUpperCase();
  final matkul = cariByKode(kode);
  if (matkul == null) {
    print('Mata kuliah $kode tidak ditemukan.');
    return;
  }
  if (krs.contains(kode)) {
    print('${matkul['nama']} sudah ada di KRS.');
    return;
  }
  final batas = hitungBatasSks(ipk);
  final sksBaru = hitungTotalSks() + (matkul['sks'] as int);
  if (sksBaru > batas) {
    print('Gagal: total SKS menjadi $sksBaru, batas SKS Anda $batas.');
    return;
  }
  final bentrok = cariBentrok(matkul);
  if (bentrok != null) {
    print('Gagal: jadwal bentrok dengan ${bentrok['nama']}.');
    return;
  }
  krs.add(kode);
  print('${matkul['nama']} berhasil diambil.');
}

/// Menu 3: menampilkan isi KRS dan total SKS.
void tampilkanKrs() {
  print('\n=== KRS Saya ===');
  if (krs.isEmpty) {
    print('KRS masih kosong.');
    return;
  }
  for (final kode in krs) {
    cetakMatkul(cariByKode(kode)!);
  }
  print('Total SKS: ${hitungTotalSks()} dari batas ${hitungBatasSks(ipk)}');
}

// ============================================================
// Fitur pilihan (pilih minimal 3, lihat README.md)
// ============================================================

/// Menu 4 [Mudah]: menghapus mata kuliah dari KRS.
void dropMatkul() {
  print('\n=== Drop Mata Kuliah ===');
  final kode = bacaTeks('Kode mata kuliah').toUpperCase();

  if (!krs.contains(kode)) {
    print('Mata kuliah $kode tidak ada di KRS.');
  }

  krs.remove(kode);
  print('Mata kuliah $kode berhasil di-drop.');
}

/// Menu 5 [Mudah]: menampilkan mata kuliah yang ditawarkan pada satu hari.
void tampilkanMatkulPerHari() {
  print('\n === Mata kuliah per-hari ===');
  final hari = bacaHari();

  for (final matkul in daftarMatkul) {
    if (matkul ['hari'] == hari) {
      cetakMatkul(matkul);
    }
  }
}

/// [Sedang] Menentukan batas SKS berdasarkan IPK.
///
/// Fungsi ini sudah dipakai di menu 2 dan 3. Selama belum dibuat, batasnya
/// selalu batasSksDefault.
int hitungBatasSks(double ipk) {
 if (ipk >= 3.00) {
    return 24;
  } else if (ipk >= 2.50) {
    return 21;
  } else if (ipk >= 2.00) {
    return 18;
  } else {
    return 15;
  }
}
/// Menu 6 [Sedang]: menampilkan jadwal kuliah dari KRS, dikelompokkan per hari.
void tampilkanJadwal() {
   print('\n=== Jadwal Kuliah Saya ===');
  if (krs.isEmpty) {
    print('KRS masih kosong.');
    return;
  }

  for (final hari in Hari.values) {
    var adaKuliah = false; // penanda: sudah ada kuliah di hari ini?

    for (final matkul in daftarMatkul) {
      if (matkul['hari'] == hari && krs.contains(matkul['kode'])) {
        // Nama hari dicetak sekali saja, saat kuliah pertama ditemukan.
        if (!adaKuliah) {
          print('${hari.name}:');
          adaKuliah = true;
        }
        print('  ${matkul['mulai']}-${matkul['selesai']} ${matkul['nama']}');
      }
    }
  }
}


/// [Sulit] Mencari mata kuliah di KRS yang jadwalnya bentrok dengan [baru].
///
/// Fungsi ini sudah dipakai di menu 2. Selama belum dibuat, tidak pernah ada
/// jadwal bentrok.
Map<String, dynamic>? cariBentrok(Map<String, dynamic> baru) {
  final mulaiBaru = baru['mulai'] as int;
  final selesaiBaru = baru['selesai'] as int;
 
  for (final kode in krs) {
    final lama = cariByKode(kode)!;
    final mulaiLama = lama['mulai'] as int;
    final selesaiLama = lama['selesai'] as int;
 
    // Bentrok jika harinya sama DAN jamnya beririsan.
    // Contoh: 8-11 dan 10-13 -> 8 < 13 dan 10 < 11 -> bentrok.
    //         8-10 dan 10-14 -> 10 < 10 salah        -> tidak bentrok.
    final hariSama = lama['hari'] == baru['hari'];
    final jamBeririsan = mulaiBaru < selesaiLama && mulaiLama < selesaiBaru;
 
    if (hariSama && jamBeririsan) {
      return lama;
    }
  }
  return null;
}

/// Menu 7 [Sulit]: mencetak KRS lengkap dengan identitas mahasiswa.
void cetakKrsLengkap() {
  final batas = hitungBatasSks(ipk);
  final total = hitungTotalSks();
 
  print('\n========== KARTU RENCANA STUDI ==========');
  print('Nama : $namaMahasiswa');
  print('NIM  : $nimMahasiswa');
  print('IPK  : ${ipk.toStringAsFixed(2)} (batas $batas SKS)');
  print('-----------------------------------------');
 
  if (krs.isEmpty) {
    print('Belum ada mata kuliah di KRS.');
  } else {
    var nomor = 1;
    for (final kode in krs) {
      final matkul = cariByKode(kode)!;
      final hari = matkul['hari'] as Hari;
      print(
        '$nomor. ${matkul['kode']} ${matkul['nama']} (${matkul['sks']} SKS) '
        '- ${hari.name} ${matkul['mulai']}-${matkul['selesai']}',
      );
      nomor++;
    }
  }
 
  print('-----------------------------------------');
  print('Total SKS: $total');
  print('Sisa SKS : ${batas - total}');
}
