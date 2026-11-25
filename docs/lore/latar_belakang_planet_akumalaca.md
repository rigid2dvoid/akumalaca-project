# 🪐 DOKUMENTASI SETTING WORLD: PLANET AKUMALACA

**Nama Tempat:** Planet Akumalaca (Sektor Bulan & Pembuangan Luar Angkasa)

**Tipe Level:** 2D Side-Scroller Stage / Horizontal Stage

**Gaya Visual:** Sci-Fi Cyberpunk / Cel-Shaded Dystopian Space

---

## 📌 1. OVERVIEW & CERITA PLANET

**Akumalaca** adalah sebuah bulan industri terbengkalai yang mengorbit di pinggiran galaksi *Cyber-Nebu*. Dahulu, planet ini digunakan sebagai fasilitas penambangan energi dan tempat pembuangan limbah sisa komponen mekanis dari peradaban kota metropolitan luar angkasa.

Kini, Akumalaca menjadi wilayah tak berhukum (*lawless zone*) yang dikuasai oleh para *Scavenger* dan sindikat penjahat cybernetic, termasuk **Monoseeds**. Di permukaan bulan inilah **Jack O' Way** harus bertahan hidup dan berburu suku cadang berharga di tengah pusaran galaksi yang dingin.

---

## 📌 2. ELSEN DESAIN VISUAL BACKGROUND

Sesuai dengan konsep aset panggung 2D *side-scroller* (pergerakan pemain kiri-kanan), latar visual Planet Akumalaca dibagi menjadi 3 lapisan kedalaman (*parallax depth*):

### **A. Foreground (Area Menapak / Walkable Ground):**
* **Struktur Jalan:** Lapisan *platform* berbahan pelat logam industri yang telah tererosi debu bulan dan berkarat, dilengkapi jalur sirkuit daya oranye redup.
* **Permukaan Tanah:** *Regolith* (debu bulan) berwarna abu-abu gelap dengan kawah-kawah kecil dan sisa reruntuhan kabel mekanis. Tempat karakter utama (*Jack O' Way*) dan musuh (*Monoseeds*) berpijak serta bertarung.

### **B. Midground (Fasilitas Terbengkalai):**
* **Bangunan Industri:** Stasiun pemantau, antena komunikasi, dan kubah habitat penambangan tua yang tertutup debu luar angkasa.
* **Pencahayaan:** Indikator lampu oranye dan terminal neon yang masih menyala redup secara sporadis.

### **C. Background (Luar Angkasa & Galaksi):**
* **Pemandangan Utama:** Pusaran galaksi spiral raksasa (*Galactic Nebula*) berwarna biru-ungu magis yang mendominasi langit.
* **Benda Langit:** Menampilkan planet tetangga, bulan kecil, dan gugusan bintang terang yang memberikan kontras dingin pada lingkungan yang sepi.

---

## 📌 3. TEKNIS INTEGRASI KE GAME ENGINE (2D PARALLAX)

Untuk mengimplementasikan aset *background* Akumalaca ini ke dalam **Unity / Godot**:

1. **Layering (Sorting Layers):**
   * `Background_Galaksi` (Kecepatan scroll 0x – diam/statis).
   * `Midground_Bangunan` (Kecepatan scroll 0.2x – memberi efek kedalaman).
   * `Foreground_Platform` (Kecepatan scroll 1.0x – sinkron dengan pergerakan kamera player).

2. **Collision Area:**
   * Memasang `BoxCollider2D` atau `EdgeCollider2D` tepat di atas batas garis pelat baja lantai agar Jack O' Way dan Monoseeds dapat menapak dengan presisi.