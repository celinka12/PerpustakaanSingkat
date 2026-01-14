<img width="205" height="36" alt="image" src="https://github.com/user-attachments/assets/3cf0d572-6819-4774-89ce-257429e3fd8f" /># PerpustakaanSingkat
Tugas Sertifikasi 

aplikasi perpustakaan sederhana berbasis **SwiftUI** dengan backend **Supabase**.
Aplikasi ini punya 2 mode utama:

1. **Catalog (Public / User)**  
   Pengguna bisa melihat katalog buku + cari judul/author/ISBN.
   
3. **Staff (Authenticated)**  
   Petugas dapat melihat daftar peminjaman (Loans), membuat peminjaman baru, melihat daftar buku, menghapus buku dan logout.

Project ini menerapkan arsitektur **MVVM (Model - View - ViewModel)** dengan `LibraryService` sebagai layer API Supabase.

---

## ✨ Features

### 📚 Catalog (Public)
- Menampilkan daftar buku (katalog)
- Search buku berdasarkan:
  - Title
  - Author
  - ISBN
  - Category
- Menampilkan cover buku dari URL (`cover_url`)
- Pull-to-refresh katalog
- Tombol **Petugas** untuk Login staff
  
> Implementasi: `CatalogView` + `CatalogViewModel`

### 👩🏻‍💼 Staff Mode (Setelah Login)
#### ✅ Loans
- Menampilkan daftar peminjaman
- Menampilkan status loan dalam bentuk chip warna (returned / on_loan / overdue)
- Menampilkan detail loan items (buku yang dipinjam) langsung di tiap row
- Auto-load detail items per loan (lazy load + cache)
- Create Loan (sheet form)
- Delete book 

> Implementasi: `LoansViewModel` + `CreateLoanView` + section loans di `StaffHomeView`

#### ✅ Books
- Menampilkan semua buku untuk pengguna (view-only)
- Search by title/author/ISBN
- Menampilkan cover buku
- Soft delete buku dengan tombol trash per row (khusus petugas)

> Implementasi: `StaffBooksViewModel` + `BooksSectionView`


#### ✅ Account
- Halaman account staff
- Logout

> Implementasi: `AuthViewModel.signOut()`

---

## 🧱 Architecture (MVVM)

Project menggunakan MVVM agar code lebih clean:
- **Views**: UI SwiftUI (`CatalogView`, `LoginView`, `StaffHomeView`, `ContentView`, `CreateLoanView`)
- **ViewModels**: logic state + async actions (`CatalogViewModel`, `LoansViewModel`,`AuthViewModel`,`LoginViewModel`,`StaffBooksViewModel`,`Models`,`LibraryAppFinalApp`)
- **Service Layer**: komunikasi ke Supabase (LibraryService)
- **Models**: `Book`, `Member`, `Loan`, `LoanItem`, `LoanListItem`, `LoanItemWithBook`, `MemberCurrentLoanRow`

---

## 📂 File Overview 

### 1) `ContentView.swift`
Root halaman aplikasi.
- Jika `auth.session == nil` → tampil `CatalogView`
- Jika login → tampil `StaffHomeView`

> File: `ContentView.swift`

---

### 2) `AuthViewModel.swift`
Auth handler utama (Supabase Auth).
- Menyimpan session: `@Published var session: Session?`
- Listen perubahan auth state dari Supabase (signed in/out/refresh token)
- Method:
  - `signIn(email:password:)`
  - `signOut()`

> File: `AuthViewModel.swift`

---

### 3) `CatalogView.swift`
Halaman katalog untuk user/public.
- Menampilkan list buku
- Searchable
- Cover pakai `BookCoverView` dengan `AsyncImage`
- Tombol toolbar “Petugas” → menampilkan `LoginView` via `.sheet`

> File: `CatalogView.swift`

---

### 4) `CatalogViewModel.swift`
State & logic untuk catalog:
- `@Published var books`
- `@Published var query`
- `filtered` computed property untuk hasil pencarian
- `load()` fetch data dari service:
  - `service.fetchAvailableBooks()`

> File: `CatalogViewModel.swift`

---

### 5) `LoginView.swift`
UI login staff.
- Form input email & password
- Tombol login menjalankan `LoginViewModel.login(auth:)`
- Error message ditampilkan dari `auth.errorMessage`

> File: `LoginView.swift`

---

### 6) `LoginViewModel.swift`
Logic login form:
- `email`, `password`, `isLoading`
- `canSubmit` untuk enable/disable tombol login
- `login(auth:)` memanggil `auth.signIn(...)`

> File: `LoginViewModel.swift`

---

### 7) `StaffHomeView.swift`
Halaman staff setelah login.
Menggunakan `TabView` berisi 3 tab:

- Loans tab → `LoansSectionView`
- Books tab → `BooksSectionView`
- Account tab → `AccountSectionView`

Loans:
- `@StateObject vm = LoansViewModel()`
- menampilkan loan list + items detail
- toolbar:
  - refresh (arrow.clockwise)
  - create (plus)
- open sheet create: `CreateLoanView(vm:onSaved:)`

Books:
- `@StateObject vm = StaffBooksViewModel()`
- searchable
- list buku + cover
- tombol trash per row (soft delete)

Account:
- logout pakai `AuthViewModel.signOut()`

> File: `StaffHomeView.swift`

---

### 8) `LoansViewModel.swift`
ViewModel paling besar (menggabungkan 2 feature):
1. loans list
2. create loan form state

#### Loans List
- load loans: `loadLoans()`
- auto hitung status overdue dari service:
  - `fetchLoansWithOverdue()`
- lazy-load items per loan:
  - `loadItemsIfNeeded(for:)`
- caching:
  - `itemsByLoan`
  - `loadingLoanIds`

#### Create Loan Form
- input:
  - memberName
  - selectedBookIDs
  - notes
  - loanDate
- computed:
  - `dueDateISO` (loanDate + 7 hari)
  - `canSaveCreateLoan`
  - `filteredBooks`
  - `selectedBooks`
- actions:
  - `pickBook`, `removeBook`, `resetCreateForm`
- saving:
  - `saveNewLoan()`:
    1) validasi
    2) cari / buat member
    3) create loan + loan_items via service

> File: `LoansViewModel.swift`

---

### 9) `CreateLoanView.swift`
Sheet/form create loan.
Menggunakan `ObservedObject var vm: LoansViewModel` sehingga state form langsung dari LoansViewModel.

Isi utama:
- isi nama peminjam
- pilih tanggal loan & due date
- search buku → pilih buku
- list selected books + tombol hapus
- save -> memanggil `vm.saveNewLoan()`

> File: `CreateLoanView.swift`

---

### 10) `StaffBooksViewModel.swift`
ViewModel untuk staff books:
- load semua buku: `fetchAllBooks()`
- soft delete:
  - `trash(book:)`
  - `trashAllBooks()`
- setelah delete -> reload list

> File: `StaffBooksViewModel.swift`

---

## 🗄️ Supabase Database Notes

### Soft Delete Book 
Project mengarah ke soft delete agar delete tidak error karena ada relasi (FK) seperti `loan_items.book_id`.


```sql
alter table public.books
add column if not exists is_deleted boolean not null default false;
```
Database pada project LibraryAppFinal menggunakan Supabase (PostgreSQL) dan dirancang untuk mendukung sistem perpustakaan sederhana yang mencakup:

1. penyimpanan katalog buku,
2. data anggota/peminjam,
3. transaksi peminjaman,
4. dan detail buku yang dipinjam pada setiap transaksi.

Struktur database menggunakan konsep relasi one-to-many dan many-to-many melalui tabel penghubung (loan_items). Dengan desain ini, satu transaksi peminjaman dapat mencatat lebih dari satu buku dalam satu kali peminjaman.

Detail tabel :
1. Books
Tabel books berfungsi sebagai penyimpanan data master buku (katalog). Data pada tabel ini ditampilkan pada halaman katalog untuk pengguna dan halaman manajemen buku untuk staff.
Kolom utama:
id (uuid) : Primary key buku
title (text) : Judul buku
author (text) : Nama penulis
category (text) : Kategori buku
isbn (text) : ISBN buku
published_year (int4) : Tahun terbit
total_copies (int4) : Total jumlah buku
available_copies (int4) : Jumlah buku tersedia untuk dipinjam
cover_url (text) : URL gambar cover buku
created_at, updated_at : Timestamp pembuatan dan update data

2. Members
Tabel members menyimpan data anggota/peminjam yang melakukan transaksi peminjaman.
Kolom utama:
id (uuid) : Primary key member
member_code (text) : Kode member (identitas unik)
name (text) : Nama peminjam
email, phone, address : Data tambahan (opsional)
created_at : Timestamp data dibuat

3. Loans
Tabel loans menyimpan transaksi peminjaman sebagai bagian header data. Satu record loans merepresentasikan satu kegiatan peminjaman oleh satu member.
Kolom utama:
id (uuid) : Primary key loan
member_id (uuid) : Foreign key ke tabel members
loan_date (date) : Tanggal peminjaman
due_date (date) : Tanggal jatuh tempo
status (text) : Status peminjaman (contoh: on_loan, returned, overdue)
notes (text) : Catatan tambahan
created_at, updated_at : Timestamp pembuatan dan update data

4. Loan_items
Tabel loan_items berfungsi sebagai tabel detail yang menghubungkan transaksi loans dengan books. Tabel ini memungkinkan satu transaksi peminjaman untuk berisi beberapa buku.
Kolom utama:
id (uuid) : Primary key item
loan_id (uuid) : Foreign key ke tabel loans
book_id (uuid) : Foreign key ke tabel books
qty (int4) : Jumlah copy buku yang dipinjam pada transaksi tersebut
returned_qty (int4) : Jumlah buku yang sudah dikembalikan
created_at : Timestamp data dibuat

Relationship :

One Member → Many Loans
members.id → loans.member_id
Artinya: satu member dapat memiliki beberapa transaksi peminjaman.

One Loan → Many Loan Items
loans.id → loan_items.loan_id
Artinya: satu transaksi peminjaman dapat berisi banyak buku.

One Book → Many Loan Items
books.id → loan_items.book_id
Artinya: satu buku dapat dipinjam berkali-kali dalam transaksi yang berbeda.

🔄<img width="2414" height="1502" alt="supabase-schema-dpcxjwihdfgrgobvhxlq" src="https://github.com/user-attachments/assets/83caf561-6703-48f9-835a-4c3ba4405282" />

ERD : 
<img width="1526" height="1061" alt="ER Diagram drawio" src="https://github.com/user-attachments/assets/e7c3c8a8-19b8-4a5d-8c7b-3e72ce5eaf71" />

FlowChart

flowchart TD
    A([Start App]) --> B{Auth Session ada?}

    B -- Tidak --> C[CatalogView<br/>Browse & Search Books]
    C --> D[Tap "Petugas"]
    D --> E[LoginView<br/>Input Email & Password]
    E --> F{Login Berhasil?}
    F -- Tidak --> E
    F -- Ya --> G[StaffHomeView (TabView)]

    B -- Ya --> G

    G --> H[Tab: Loans]
    G --> I[Tab: Books]
    G --> J[Tab: Account]

    J --> K[Logout]
    K --> C

flowchart TD
    A([Staff klik + Create Loan]) --> B[CreateLoanView<br/>Input Member Name]
    B --> C[Pick Loan Date]
    C --> D[Search Book]
    D --> E{Book Available?}

    E -- No --> D
    E -- Yes --> F[Add Book to Selected List]

    F --> G{Tambah buku lain?}
    G -- Yes --> D
    G -- No --> H[Klik Save]

    H --> I{Member sudah ada?}
    I -- No --> J[Insert into members]
    I -- Yes --> K[Use existing member_id]
    J --> L[Insert into loans]
    K --> L

    L --> M[Insert loan_items (for each selected book)]
    M --> N[Update books.available_copies = available_copies - qty]
    N --> O([Done: Loan Created])
    O --> P[Reload Loans List]

flowchart LR
    A[members] -->|1 member has many| B[loans]
    B -->|1 loan has many| C[loan_items]
    D[books] -->|1 book can appear in many| C


App Flow
App dibuka → ContentView
Jika belum login → CatalogView
Staff klik tombol Petugas → LoginView
Login sukses → session ada → ContentView otomatis pindah ke StaffHomeView


Staff bisa:
lihat loans & create loan
lihat books + trash buku
logout → balik ke catalog


---
App : 
![WhatsApp Image 2026-01-11 at 05 21 42 (1)](https://github.com/user-attachments/assets/502a463e-5e88-478e-b63f-13e4725ac2f8)
Menampilkan katalog buku dan search bar 

![WhatsApp Image 2026-01-11 at 05 21 42](https://github.com/user-attachments/assets/7b0387e8-c5e5-4e0c-b349-c79f76b3b621)
Menampilkan status peminjaman para pengguna dan detail peminjaman

![WhatsApp Image 2026-01-11 at 05 24 29](https://github.com/user-attachments/assets/de47ff0b-4241-402a-99fc-703cf458fc6e)
Menampilkan form peminjaman yang diisi oleh petugas perpustakaan dan dapat melihat ketersediaan buku yang ingin dipinjam

---
Test Case Aplikasi : 

Pengguna/ USer Library:
<img width="447" height="528" alt="Screenshot 2026-01-14 at 17 24 54" src="https://github.com/user-attachments/assets/67e2730b-9132-4fd9-b132-a6b193897dea" />

Hasil Dokumentasi: 

<img width="365" height="792" alt="image" src="https://github.com/user-attachments/assets/011ba77a-e2b2-4752-8e1f-e3e0387003de" />
<img width="365" height="792" alt="image" src="https://github.com/user-attachments/assets/09981a91-cd7a-43dc-8109-86e7f714a771" />


Staff Library:

T03: Buka Halaman Login Staff

<img width="203" height="560" alt="Screenshot 2026-01-14 at 17 29 30" src="https://github.com/user-attachments/assets/667e13a6-2dd7-4460-8c9c-3bf9adb583e3" />

Hasil Dokumentasi:

<img width="365" height="792" alt="image" src="https://github.com/user-attachments/assets/59d29b99-93f5-44ae-a517-42b2b187ae52" />

T04 : Login gagal (password salah)
<img width="203" height="560" alt="Screenshot 2026-01-14 at 17 31 01" src="https://github.com/user-attachments/assets/ea07cf53-b404-424f-a0ed-fa440c0671cc" />
Hasil Dokumentasi:
<img width="365" height="792" alt="image" src="https://github.com/user-attachments/assets/e4766e93-8bda-45c0-8ad0-921e3a210595" />

T05: Login berhasil (password benar)
<img width="248" height="560" alt="Screenshot 2026-01-14 at 17 33 33" src="https://github.com/user-attachments/assets/6ec839d7-6f5e-42d7-9153-0f13b1721965" />
Hasil Dokumentasi :
<img width="365" height="792" alt="image" src="https://github.com/user-attachments/assets/98d94b27-168c-46e2-a26d-d411f00a03bc" />

T06: Load daftar Member loan
<img width="197" height="560" alt="Screenshot 2026-01-14 at 17 34 46" src="https://github.com/user-attachments/assets/8b2a32c0-56f5-4453-886b-eea2490a69aa" />
Hasil Dokumentasi :
<img width="365" height="792" alt="image" src="https://github.com/user-attachments/assets/98d94b27-168c-46e2-a26d-d411f00a03bc" />

T07: Membuka form create loan
<img width="211" height="560" alt="Screenshot 2026-01-14 at 17 35 49" src="https://github.com/user-attachments/assets/e65337cd-0103-4789-abed-b6dc0e90cf98" />
Hasil Dokumentasi :
<img width="365" height="792" alt="image" src="https://github.com/user-attachments/assets/77c2d0df-7317-4890-96a4-936bc3aa432b" />

T08: Validasi Create Loan (tidak bisa disave)
<img width="187" height="563" alt="Screenshot 2026-01-14 at 17 37 02" src="https://github.com/user-attachments/assets/7257f4f9-4574-4db3-bca5-930159c27c2b" />
Hasil Dokumentasi : 
<img width="1206" height="2622" alt="Simulator Screenshot - iPhone 17 - 2026-01-14 at 17 37 16" src="https://github.com/user-attachments/assets/a764a15c-f0d6-45d0-b5fe-4927a968fbe4" />

T09: Create Loan berhasil
<img width="211" height="563" alt="Screenshot 2026-01-14 at 17 38 55" src="https://github.com/user-attachments/assets/2efcfe00-7949-4bb5-9f52-4ada7c12a518" />
Hasil Dokumentasi : 
<img width="1206" height="2622" alt="Simulator Screenshot - iPhone 17 - 2026-01-14 at 17 39 36" src="https://github.com/user-attachments/assets/dc707d6d-02d4-43d2-96ef-b3da103ecc4c" />

T10: Load daftar books staf
<img width="224" height="563" alt="Screenshot 2026-01-14 at 17 39 57" src="https://github.com/user-attachments/assets/33c53eea-4bc1-4a73-a32d-76e00174a3d6" />
Hasil Dokumentasi : 
<img width="1206" height="2622" alt="Simulator Screenshot - iPhone 17 - 2026-01-14 at 17 40 29" src="https://github.com/user-attachments/assets/af2709db-3890-43e4-9cad-71ab834fe0ca" />

T11: Soft delete buku (trash)
<img width="240" height="563" alt="Screenshot 2026-01-14 at 17 41 08" src="https://github.com/user-attachments/assets/613a1260-5e2e-4342-b4bb-0fcc4dc3b679" />
Hasil Dokumentasi : 
<img width="1206" height="2622" alt="Simulator Screenshot - iPhone 17 - 2026-01-14 at 17 41 23" src="https://github.com/user-attachments/assets/e523372a-b4e2-4233-ad7f-13acc57a8fcf" />
<img width="1206" height="2622" alt="Simulator Screenshot - iPhone 17 - 2026-01-14 at 17 41 32" src="https://github.com/user-attachments/assets/04666637-cd1e-44eb-8148-eeee7c95106d" />

T12: Logout
<img width="209" height="563" alt="Screenshot 2026-01-14 at 17 42 11" src="https://github.com/user-attachments/assets/dbef2b60-ce0f-4a5c-936f-484a7bed1d45" />
Hasil Dokumentasi : 
<img width="1206" height="2622" alt="Simulator Screenshot - iPhone 17 - 2026-01-14 at 17 42 41" src="https://github.com/user-attachments/assets/bad924a8-139d-4881-b710-a4c8f8716ae6" />



THANK YOU 


Author


Celinka Eira — PerpustakaanSingkat

