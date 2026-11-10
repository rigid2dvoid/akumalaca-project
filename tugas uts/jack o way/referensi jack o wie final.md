# 📝 DRAFT LAPORAN DESAIN KARAKTER GAME (PERTEMUAN 7)

**Mata Kuliah:** Character Game / Pemodelan Game  
**Karakter:** Jack O' Way (Cyberpunk Scavenger 2D)  
**Status Dokumen:** Final Draft (Siap Export / Cetak)

---

## 📌 BAB 1: REFERENSI VISUAL & INSPIRASI DESAIN

Desain karakter **Jack O' Way** dirancang berdasarkan pendekatan studi konsep *cyberpunk scavenger* dan *dystopian engineer*. Untuk memastikan aspek fungsionalitas dan estetika karakter tetap realistis serta memiliki dasar visual yang kuat, beberapa referensi visual dari platform seni digital seperti ArtStation dan DeviantArt digunakan sebagai acuan acuan bentuk dan pencahayaan:

1. **Scavenger & Tactical Outfit Concept (ArtStation):**  
   * **URL:** [https://www.artstation.com/artwork/2853mx](https://www.artstation.com/artwork/2853mx)  
   * **Acuan:** Referensi bentuk jaket taktis *dark slate blue*, rompi utility, dan estetika perlengkapan taktis kumal/survival khas *scavenger*.
2. **Cybernetic Hard-Surface Mechanical Arm (ArtStation):**  
   * **URL:** [https://www.artstation.com/artwork/Qn91vL](https://www.artstation.com/artwork/Qn91vL)  
   * **Acuan:** Struktur artikulasi persendian robotik, aksen sirkuit neon oranye, dan material logam terabrasi untuk lengan mekanik kanan.
3. **Cyberpunk Male Character & Visor Concept (DeviantArt):**  
   * **URL:** [https://www.deviantart.com/wonderlandartworks/art/Cyberpunk-Character-Concept-Art-954549393](https://www.deviantart.com/wonderlandartworks/art/Cyberpunk-Character-Concept-Art-954549393)  
   * **Acuan:** Penggunaan kacamata *visor* holografik dengan bentuk 'V' terbalik serta skema pencahayaan kontras pada wajah.

---

## 📌 BAB 2: ANALISIS ELEMEN DESAIN KARAKTER

 visual karakter Jack O' Way diuraikan berdasarkan **4 Elemen Utama Pemodelan Karakter Game**:

### 1. Siluet (Silhouette)
* **Bentuk Dasar:** Siluet tubuh maskulin atletis dengan ketidakseimbangan simetris (*asymmetrical balance*) yang mencolok pada lengan bagian kanan.
* **Fungsi Game:** Memudahkan pemain mengenali orientasi dan jenis karakter dalam *gameplay* 2D (Side-scroller / Top-down) bahkan dalam kondisi pencahayaan minim.
* **Fitur Khas:** Siluet *collar* jaket yang tinggi, saku-saku taktis pada celana cargo, dan bentuk lengan kanan cybernetic yang lebih tebal dibanding lengan kiri.

### 2. Warna (Color Palette & Harmony)
* **Warna Dominan:** *Dark Slate Blue / Charcoal Grey* (Memberikan kesan tertutup, praktis, dan menyatu dengan lingkungan perkoatan dystopian).
* **Warna Aksentuasi (Focal Point):** *Electric Neon Orange* ($\text{HEX } \#\text{FF6600}$) pada *visor* holografik, jalur sirkuit dada, dan *core indicator* lengan mekanik.
* **Harmoni Warna:** Menggunakan kontras *Complementary/Analogous Warm-Cold* antara warna biru-abu dingin pada pakaian dan aksen oranye hangat yang menyala.

### 3. Ekspresi & Gestur (Expression & Attitude)
* **Raut Wajah:** Stoik, tenang, dan waspada. Terlihat dari rahang tegas dan tatapan tersembunyi di balik *holographic visor*.
* **Postur Tubuh:** *Ready-to-action stance* (Kaki sedikit terbuka, lengan mekanik siap memanipulasi teknologi atau bertahan).

### 4. Kostum & Atribut (Costume & Props)
* **Outerwear:** Jaket taktis berlapis dengan kerah berdiri (*high collar*) dan rompi *utility vest* yang terintegrasi dengan modul sirkuit daya.
* **Cybernetic Limb:** Lengan mekanik kanan dari bahu hingga ujung jari dengan kabel internal terekspos dan lampu indikator Oranye.
* **Peralatan Teknis:** Gadget pemindai signal (*communicator*) terpasang di pinggang kiri, serta sepatu bot lapis baja.

---

## 📌 BAB 3: PENERAPAN 4 PRINSIP DESAIN KARAKTER

1. **Readability (Keterbacaan Visual):**  
   Titik fokus visual (*focal point*) langsung tertuju pada bagian atas tubuh (wajah dengan visor menyala) dan lengan kanan cybernetic, mempermudah identifikasi pergerakan aksi pemain.
2. **Silhouette Distinction:**  
   Bentuk lengan mekanik asimetris memastikan Jack O' Way mudah dibedakan secara langsung dari entitas NPC atau musuh lain.
3. **Color Harmony & Functionality:**  
   Penggunaan warna oranye neon bukan hanya sekadar estetika, melainkan penanda status daya (*energy level*) dari atribut cybernetic karakter.
4. **Storytelling in Design (Naratif Visual):**  
   Goresan luka pada jaket, permukaan logam lengan yang tergores, dan aksesoris perkakas darurat menceritakan latar belakang Jack sebagai seorang teknisi *scavenger* yang bertahan hidup di dunia keras.

---

## 📌 BAB 4: LEMBAR TURNAROUND SHEET (ASLE DESAIN 2D)

* **Tampak Depan (Front View):** Menampilkan proporsi utuh wajah, visor V-terbalik, sirkuit rompi, serta detail simetris pakaian.
* **Tampak Samping (Side View):** Menampilkan profil ketebalan lengan mekanik kanan, saku taktis samping, dan postur berdiri.
* **Tampak Belakang (Back View):** Menampilkan detail bagian belakang jaket, sambungan kabel lengan robotik, dan sabuk taktis.

---

## 📌 BAB 5: RENCANA INTEGRASI GAME ENGINE & ANIMASI

1. **Proses Rigging/Animasi:**  
   * Memisahkan segmen badan (Kepala, Dada, Lengan Kanan, Lengan Kiri, Kaki) ke dalam format PNG transparan.
   * Mengolah animasi dasar (*Idle, Walk, Interact*) menggunakan **Meta Animated Drawings** / **Spine 2D**.
2. **Integrasi Engine (Unity / Godot):**  
   * Import aset ke dalam Sprite Sheet 2D.
   * Menyiapkan controller pergerakan karakter (Input System) dan komponen *Collider* serta *Rigidbody2D*.