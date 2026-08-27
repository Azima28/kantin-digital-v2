--
-- PostgreSQL database dump
--

\restrict 71S0OPXuxl9tCU5Q9QkZmdmi9RVlkmaBAiGd4NGGmiRW5sEpyNsHFqI8jV7f1cw

-- Dumped from database version 16.15
-- Dumped by pg_dump version 16.15

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Data for Name: profiles; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.profiles VALUES ('51325215-0176-4324-bb74-4e973bcfff13', 'nasgor@canteen.com', 'Stan Nasi Goreng', 'petugas_kantin', '$2a$06$He4Azy0ueOdREJslzjjvLOCeIUqGjo9El7pyYrHJkG1IwwT521AC2', 'nasgor_stan', NULL, NULL, true, NULL, NULL, '2026-06-19 16:19:58.165217+07');
INSERT INTO public.profiles VALUES ('98dd238b-b56c-4d27-8125-e0624385d2e7', 'animas@gmail.com', 'Ani masi bagus', 'petugas_kantin', '$2a$06$W5lwcS65HYd9DZfG/XraHO15E14DcGPy/TjzTQUNSaQYUCmpy7KUK', 'ani', NULL, '089647543543', true, NULL, NULL, '2026-06-25 16:48:22.889917+07');
INSERT INTO public.profiles VALUES ('6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 'petugas@sekolah.sch.id', 'Petugas Kantin', 'petugas_kantin', '$2a$06$9j70LNmJLjC12bsS0WaYQej0H5HmJSoGkEO5T/rQD8P.OcMF49PvO', 'petugas', NULL, NULL, true, NULL, NULL, '2026-06-15 11:13:07.387566+07');
INSERT INTO public.profiles VALUES ('6a4e32d5-45c1-4b10-86d9-f5d60b571111', 'salim.subarjo@example.com', 'Salim Subarjo', 'parent', '$2a$06$.zWi3ua1DLI15929LOqSOe0mR.Cvzd7zOPQjlwWI0y6LYAPO.ELRW', 'salim_s', NULL, '+62 812 3456 7890', true, NULL, NULL, '2026-06-17 11:41:33.797819+07');
INSERT INTO public.profiles VALUES ('92e9992f-d627-4070-b2e7-38905d934814', 'parent.budi@sekolah.sch.id', 'Orang Tua Budi Santoso', 'parent', '$2a$06$cZLGZmtFQKiHwB7y4tijJ.PqcQ3k7WBkAgKA/aAY743GTNH6DaapW', 'parent_student_20260003', NULL, NULL, true, NULL, NULL, '2026-06-19 16:01:40.040958+07');
INSERT INTO public.profiles VALUES ('e19a8524-9b2a-4ae8-a177-62c21760e70b', 'parent.ahmad@sekolah.sch.id', 'Orang Tua Ahmad Fauzi', 'parent', '$2a$06$DFapnnty/avfDnpKvH8CUeW7VK5sCzhhxLTlnHrJhgUPt6RLkUCr.', 'parent_student_20260001', NULL, NULL, true, NULL, NULL, '2026-06-19 16:01:40.040958+07');
INSERT INTO public.profiles VALUES ('37e22cf7-173c-4351-b766-24574e25a630', 'parent.test4@test.com', 'Orang Tua Test Student4', 'parent', '$2a$06$5bNaj5ZDy1P/QoJFdHvpH.noRRuqVIWdgGWLsq1bR00e2JYfrVY7u', 'parent_test_std4', NULL, NULL, true, NULL, NULL, '2026-06-19 16:01:40.040958+07');
INSERT INTO public.profiles VALUES ('b68788d2-6643-4310-a18f-723d11a7b1d9', 'parent.siti@sekolah.sch.id', 'Orang Tua Siti Aminah', 'parent', '$2a$06$/DdeGzKQVLx5CAuRK/uGgeItkxcWvpOxagRLz4Hq7aUrjqvs9.Awu', 'parent_student_20260002', NULL, NULL, true, NULL, NULL, '2026-06-19 16:01:40.040958+07');
INSERT INTO public.profiles VALUES ('d511689b-7ae6-4fb1-bbbd-e5d4ec35d9ca', 'parent.test5@test.com', 'Orang Tua Test Student5', 'parent', '$2a$06$u81SUQG/p4jqzskcpXQ0ou72O6tECDvMRR06qSXhH6WXxMxyf7RUW', 'parent_test_std5', NULL, NULL, true, NULL, NULL, '2026-06-19 16:01:40.040958+07');
INSERT INTO public.profiles VALUES ('45ad99e3-5f4b-42ff-9f84-a85467cbe9b3', 'bakso@canteen.com', 'Stan Bakso', 'petugas_kantin', '$2a$06$qcxZGIQPdfqtz7yNSKQjKOee8ACxPI3Vg1knMr6VEaceFpecdebKK', 'bakso_stan', NULL, NULL, true, NULL, NULL, '2026-06-19 16:19:57.998082+07');
INSERT INTO public.profiles VALUES ('dbe4f12d-a2f2-45e0-94e8-8888bdf12345', 'budi.finance@f.com', 'Budi Hartono', 'petugas_keuangan', '$2a$06$9j70LNmJLjC12bsS0WaYQej0H5HmJSoGkEO5T/rQD8P.OcMF49PvO', 'budi_fin', NULL, '+62 857 1111 2222', true, NULL, NULL, '2026-06-17 11:41:33.797819+07');
INSERT INTO public.profiles VALUES ('225883f2-5a0c-4228-89c3-7fca0dff4221', 'test4@test.com', 'Test Student4', 'student', '$2a$06$9j70LNmJLjC12bsS0WaYQej0H5HmJSoGkEO5T/rQD8P.OcMF49PvO', 'test_std4', '20260004', NULL, false, NULL, NULL, '2026-06-19 15:31:11.351038+07');
INSERT INTO public.profiles VALUES ('dfee7423-df2d-4ea9-ac9a-0df4af6b5496', 'test5@test.com', 'Test Student5', 'student', '$2a$06$9j70LNmJLjC12bsS0WaYQej0H5HmJSoGkEO5T/rQD8P.OcMF49PvO', 'test_std5', '20260005', NULL, false, NULL, NULL, '2026-06-19 15:42:50.857972+07');
INSERT INTO public.profiles VALUES ('87c5bfac-fb35-40c6-bb9a-9b0f969d6ae4', 'siti@sekolah.sch.id', 'Siti Aminah', 'student', '$2a$06$9j70LNmJLjC12bsS0WaYQej0H5HmJSoGkEO5T/rQD8P.OcMF49PvO', 'student_20260002', '20260002', NULL, false, NULL, NULL, '2026-06-19 15:51:39.858008+07');
INSERT INTO public.profiles VALUES ('90edbc75-8cb8-4e55-8786-e121536cb659', 'budi@sekolah.sch.id', 'Budi Santoso', 'student', '$2a$06$9j70LNmJLjC12bsS0WaYQej0H5HmJSoGkEO5T/rQD8P.OcMF49PvO', 'student_20260003', '20260003', NULL, true, NULL, NULL, '2026-06-19 15:51:40.442398+07');
INSERT INTO public.profiles VALUES ('f0c16eec-fe34-4ebf-91d5-bcd5a8183d91', 'budi.fin@sekolah.sch.id', 'Budi Finance', 'petugas_keuangan', '$2a$06$9j70LNmJLjC12bsS0WaYQej0H5HmJSoGkEO5T/rQD8P.OcMF49PvO', NULL, NULL, NULL, true, NULL, NULL, '2026-06-19 16:19:52.032831+07');
INSERT INTO public.profiles VALUES ('33abd902-172f-4ab8-b560-c901120e2981', 'siti.fin@sekolah.sch.id', 'Siti Finance', 'petugas_keuangan', '$2a$06$9j70LNmJLjC12bsS0WaYQej0H5HmJSoGkEO5T/rQD8P.OcMF49PvO', NULL, NULL, NULL, true, NULL, NULL, '2026-06-19 16:19:52.532288+07');
INSERT INTO public.profiles VALUES ('fc8ac439-1256-468c-8fe3-8fa2e7ff9dcb', NULL, 'Rizki Pratama', 'student', '$2a$10$PcnVDald6gFL9R2rWbMF9.mD2ckNMW9NdQyL6A8ayS7qBP/70n2S6', 'rizki_p', '20260099', NULL, true, NULL, NULL, '2026-08-20 15:46:02.690838+07');
INSERT INTO public.profiles VALUES ('e7925276-2188-4536-b146-73935cea8065', 'boimen@sekolah.sch.id', 'Ahmad Fauzi', 'student', '$2a$06$9j70LNmJLjC12bsS0WaYQej0H5HmJSoGkEO5T/rQD8P.OcMF49PvO', 'student_20260001', '20260001', NULL, true, NULL, NULL, '2026-06-19 15:51:39.569787+07');
INSERT INTO public.profiles VALUES ('03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '20260012@sekolah.sch.id', 'Ahmad Subarjo', 'student', '$2a$06$9j70LNmJLjC12bsS0WaYQej0H5HmJSoGkEO5T/rQD8P.OcMF49PvO', 'ahmad', '20260012', NULL, true, NULL, NULL, '2026-06-15 12:29:54.575496+07');
INSERT INTO public.profiles VALUES ('cd8c7092-f250-49c8-9a66-c4f1c76a2eea', '12131434@sekolah.sch.id', 'azima', 'student', '$2a$10$oAzTEFp1q.IWLx4muRbtJOTs2rHxyj/DU0WYmyZ8.GlYS3JEWLhO2', 'azima', '12131434', '08966464632', true, NULL, NULL, '2026-08-20 15:50:49.761955+07');
INSERT INTO public.profiles VALUES ('f1e4f12d-a2f2-45e0-94e8-9999cdf99999', 'keuangan@sekolah.sch.id', 'Petugas Keuangan', 'petugas_keuangan', '$2a$06$9j70LNmJLjC12bsS0WaYQej0H5HmJSoGkEO5T/rQD8P.OcMF49PvO', 'keuangan', NULL, '+62 857 1111 3333', true, NULL, NULL, '2026-06-22 11:54:11.247001+07');
INSERT INTO public.profiles VALUES ('88888888-8888-8888-8888-888888888888', 'superadmin@kantindigital.com', 'Super Admin', 'super_admin', '$2a$06$9j70LNmJLjC12bsS0WaYQej0H5HmJSoGkEO5T/rQD8P.OcMF49PvO', 'superadmin', NULL, '+62 800 0000 0000', true, NULL, NULL, '2026-06-17 11:41:33.797819+07');


--
-- Data for Name: audit_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: canteen_operators; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.canteen_operators VALUES ('6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 'Stan Utama', 416269, true, 2000, 4.75, 4);
INSERT INTO public.canteen_operators VALUES ('98dd238b-b56c-4d27-8125-e0624385d2e7', 'Bude Ani', 0, true, 2000, 5.00, 3);
INSERT INTO public.canteen_operators VALUES ('45ad99e3-5f4b-42ff-9f84-a85467cbe9b3', 'Stan Bakso Enak', 0, true, 2000, 4.50, 2);
INSERT INTO public.canteen_operators VALUES ('51325215-0176-4324-bb74-4e973bcfff13', 'Stan Nasgor', 0, true, 2000, 4.50, 2);


--
-- Data for Name: cashier_shifts; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: finance_officers; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.finance_officers VALUES ('f0c16eec-fe34-4ebf-91d5-bcd5a8183d91', 0, '["topup", "withdrawal", "correction"]', 'SMP Terpadu', 'L1', '2026-06-19 16:19:52.032831+07');
INSERT INTO public.finance_officers VALUES ('33abd902-172f-4ab8-b560-c901120e2981', 0, '["topup", "withdrawal", "correction"]', 'SMP Terpadu', 'L2', '2026-06-19 16:19:52.532288+07');
INSERT INTO public.finance_officers VALUES ('f1e4f12d-a2f2-45e0-94e8-9999cdf99999', 0, '["topup", "withdrawal", "correction"]', 'SMP Terpadu', 'L1', '2026-06-22 11:54:11.247001+07');
INSERT INTO public.finance_officers VALUES ('dbe4f12d-a2f2-45e0-94e8-8888bdf12345', 190000, '["topup", "withdrawal", "correction"]', 'SMP Terpadu', 'L1', '2026-06-17 11:41:33.797819+07');


--
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.notifications VALUES ('42449b30-03e5-4eb7-8332-08ed4515b1ad', 'e7925276-2188-4536-b146-73935cea8065', 'Top-Up Saldo Berhasil! 💳', 'Top-up saldo sebesar Rp 20000 berhasil ditambahkan ke akun Anda.', 'topup', false, '2026-08-20 16:02:52.167898+07');
INSERT INTO public.notifications VALUES ('b318a1e8-3337-4074-874f-65ccc03d7188', 'e7925276-2188-4536-b146-73935cea8065', 'Top-Up Saldo Berhasil! 💳', 'Top-up saldo sebesar Rp 20000 berhasil ditambahkan ke akun Anda.', 'topup', false, '2026-08-20 16:03:38.842323+07');
INSERT INTO public.notifications VALUES ('16c8b08b-d4f7-407a-8d30-65eb5d1ec99e', 'cd8c7092-f250-49c8-9a66-c4f1c76a2eea', 'Top-Up Saldo Berhasil! 💳', 'Top-up saldo sebesar Rp 20000 berhasil ditambahkan ke akun Anda.', 'topup', false, '2026-08-20 16:12:11.831549+07');
INSERT INTO public.notifications VALUES ('121a4504-9bc2-40ee-82d5-f27f309ae82f', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Top-Up Saldo Berhasil! 💳', 'Top-up saldo sebesar Rp 20000 berhasil ditambahkan ke akun Anda.', 'topup', true, '2026-08-20 16:09:12.489328+07');
INSERT INTO public.notifications VALUES ('fee8926e-1ef5-4dc9-b912-5368c85d33dc', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Top-Up Saldo Berhasil! 💳', 'Top-up saldo sebesar Rp 20000 berhasil ditambahkan ke akun Anda.', 'topup', true, '2026-08-20 16:09:37.728794+07');
INSERT INTO public.notifications VALUES ('3f84deb2-cf1e-43ef-87fc-d3b9ae74ddf5', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Top-Up Saldo Berhasil! 💳', 'Top-up saldo sebesar Rp 20000 berhasil ditambahkan ke akun Anda.', 'topup', true, '2026-08-20 16:09:44.111997+07');
INSERT INTO public.notifications VALUES ('4dd467d5-3e41-47ff-a635-81e3cf9ca372', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Pesanan Berhasil Disimpan! 🛒', 'Pesanan senilai Rp 5000 (Diantar: <h1>DUAR MEK</h1>) telah dikirim ke kantin.', 'purchase', true, '2026-08-20 16:17:32.140836+07');
INSERT INTO public.notifications VALUES ('92e0b63d-4cfa-4080-a5e7-e389afb8ce9d', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Pesanan Berhasil Disimpan! 🛒', 'Pesanan senilai Rp 37000 (Diantar) telah dikirim ke kantin.', 'purchase', true, '2026-08-20 16:23:39.771356+07');
INSERT INTO public.notifications VALUES ('410b4a0c-4dd6-444b-81cb-d898dc0276c2', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Pesanan Berhasil Disimpan! 🛒', 'Pesanan senilai Rp 37000 (Diantar) telah dikirim ke kantin.', 'purchase', true, '2026-08-20 16:27:13.032939+07');
INSERT INTO public.notifications VALUES ('b4d05c4d-7eb3-47a1-a78d-33b6fa6aed93', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Pesanan Berhasil Disimpan! 🛒', 'Pesanan senilai Rp 7000 (Diantar) telah dikirim ke kantin.', 'purchase', true, '2026-08-20 16:28:29.319611+07');
INSERT INTO public.notifications VALUES ('55421647-d2f2-4f65-afeb-e98e18821f93', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Top-Up Saldo Berhasil! 💳', 'Top-up saldo sebesar Rp 50000 berhasil ditambahkan ke akun Anda.', 'topup', true, '2026-08-20 16:41:36.243917+07');
INSERT INTO public.notifications VALUES ('f5fea39d-0863-4a38-81e8-40965ceab9d0', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Pesanan Berhasil Disimpan! 🛒', 'Pesanan senilai Rp 7000 (Dimakan) telah dikirim ke kantin.', 'purchase', true, '2026-08-20 16:50:51.208786+07');
INSERT INTO public.notifications VALUES ('19c903bc-f8ec-4d1b-9d75-9d41e4125522', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Pesanan Berhasil Disimpan! 🛒', 'Pesanan senilai Rp 14000 (Dimakan) telah dikirim ke kantin.', 'purchase', true, '2026-08-20 16:52:28.483044+07');
INSERT INTO public.notifications VALUES ('13590574-0a6e-47f9-824e-9214db4bc10e', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Pesanan Berhasil Disimpan! 🛒', 'Pesanan senilai Rp 14000 (Dimakan) telah dikirim ke kantin.', 'purchase', true, '2026-08-20 16:52:53.36077+07');
INSERT INTO public.notifications VALUES ('2124f0f9-bcbc-41a3-ae6a-2465d14a4828', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Pesanan Berhasil Disimpan! 🛒', 'Pesanan senilai Rp 14000 (Dimakan) telah dikirim ke kantin.', 'purchase', true, '2026-08-20 16:53:46.494606+07');
INSERT INTO public.notifications VALUES ('460c35e0-264e-4f42-80ea-ca109afcff1d', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Pesanan Berhasil Disimpan! 🛒', 'Pesanan senilai Rp 3000 (Dimakan) telah dikirim ke kantin.', 'purchase', true, '2026-08-20 16:53:54.525184+07');
INSERT INTO public.notifications VALUES ('2b7d685e-5668-4c90-abdc-85a3316dcce0', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Pesanan Berhasil Disimpan! 🛒', 'Pesanan senilai Rp 7000 (Dimakan) telah dikirim ke kantin.', 'purchase', true, '2026-08-20 16:54:51.697016+07');
INSERT INTO public.notifications VALUES ('e483c218-4844-46f7-a4d9-61a917d61459', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Pesanan Berhasil Disimpan! 🛒', 'Pesanan senilai Rp 3000 (Dimakan) telah dikirim ke kantin.', 'purchase', true, '2026-08-20 16:55:17.524647+07');
INSERT INTO public.notifications VALUES ('1db71bc7-347b-4378-b445-0dc6d40159fb', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Pesanan Berhasil Disimpan! 🛒', 'Pesanan senilai Rp 3000 (Dimakan) telah dikirim ke kantin.', 'purchase', true, '2026-08-20 16:55:33.309697+07');
INSERT INTO public.notifications VALUES ('854f3ffb-cb34-4993-b8ff-e89cf77dc1e4', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Pesanan Berhasil Disimpan! 🛒', 'Pesanan senilai Rp 7000 (Dimakan) telah dikirim ke kantin.', 'purchase', true, '2026-08-20 16:56:11.544671+07');
INSERT INTO public.notifications VALUES ('7dff8cc9-fc66-4938-896b-2e92455a982d', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Pesanan Berhasil Disimpan! 🛒', 'Pesanan senilai Rp 10 berhasil dibuat.', 'purchase', true, '2026-08-20 16:56:57.845491+07');
INSERT INTO public.notifications VALUES ('718c7435-896f-4a2b-b0df-2a84849bf790', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Top-Up Saldo Berhasil! 💳', 'Top-up saldo sebesar Rp 100000 berhasil ditambahkan ke akun Anda.', 'topup', true, '2026-08-24 10:02:45.838666+07');
INSERT INTO public.notifications VALUES ('25d29920-8228-4be6-bd07-ead0e4649f29', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Pesanan Berhasil Disimpan! 🛒', 'Pesanan senilai Rp 30000 (Pickup) telah dikirim ke kantin.', 'purchase', true, '2026-08-24 10:02:54.656864+07');
INSERT INTO public.notifications VALUES ('7fbf5bc5-f22d-4d2e-8884-8b6b8dd8ca0c', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Transaksi Berhasil! 🛒', 'Pembayaran sukses senilai Rp 30000 di kantin sekolah.', 'purchase', true, '2026-08-24 10:03:05.746384+07');
INSERT INTO public.notifications VALUES ('359c990e-a45d-4b1e-9ae2-d46d13c39fcb', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Transaksi Berhasil! 🛒', 'Pembayaran sukses senilai Rp 15000 di kantin sekolah.', 'purchase', true, '2026-08-24 10:28:07.173621+07');
INSERT INTO public.notifications VALUES ('bf9f8de0-f35a-4740-8040-ed96a2aee79f', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Pesanan Selesai! 🎉', 'Pesanan Anda telah selesai diproses oleh stan.', 'general', false, '2026-08-27 09:59:04.524187+07');


--
-- Data for Name: orders; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.orders VALUES ('71cf0c81-aa1d-4a35-b6bb-aed0e5c30960', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Ahmad Subarjo', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 'Selesai', '', 12000, NULL, '2026-07-06 10:04:30.193646+07');
INSERT INTO public.orders VALUES ('f9aa1d8b-cf16-4572-b8ba-c0dc63201505', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Ahmad Subarjo', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 'Dibatalkan', '', 12000, NULL, '2026-07-07 14:45:55.584996+07');
INSERT INTO public.orders VALUES ('885f8570-a3ee-400a-83ff-32e6d6f84e54', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Ahmad Subarjo', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 'Selesai', NULL, 24000, NULL, '2026-07-01 11:29:48.171906+07');
INSERT INTO public.orders VALUES ('f76f8d07-ac8e-4888-902b-bddbec5f7674', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Ahmad Subarjo', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 'Dibatalkan', '', 12000, NULL, '2026-07-07 14:51:39.718423+07');
INSERT INTO public.orders VALUES ('cf6e5023-6ca8-4248-a87f-90ae6639806d', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Ahmad Subarjo', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 'Selesai', NULL, 12000, NULL, '2026-07-01 11:46:50.027454+07');
INSERT INTO public.orders VALUES ('4c3179f9-eca8-40a9-b356-1bebb10a0eb7', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Ahmad Subarjo', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 'Dibatalkan', '', 1111, NULL, '2026-07-07 16:33:06.780491+07');
INSERT INTO public.orders VALUES ('b915d63d-1008-4f5f-bed5-4cd84c8d61c7', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Ahmad Subarjo', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 'Dibatalkan', '', 1111, NULL, '2026-07-07 16:27:25.276699+07');
INSERT INTO public.orders VALUES ('1a479765-0bea-4e57-87ce-43a7ec9e1516', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Ahmad Subarjo', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 'Dibatalkan', '', 1111, NULL, '2026-07-07 15:29:24.713339+07');
INSERT INTO public.orders VALUES ('7f43d5f2-11f8-4c62-b6fc-00a69c47ae99', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Ahmad Subarjo', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 'Dibatalkan', '', 12000, NULL, '2026-07-01 14:48:17.381328+07');
INSERT INTO public.orders VALUES ('6a7a00b2-9215-44a8-b3d6-54fefeb21070', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Ahmad Subarjo', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 'Dibatalkan', '', 12000, NULL, '2026-07-07 15:12:20.317346+07');
INSERT INTO public.orders VALUES ('faaebebf-61cd-416a-a50e-3b63a4392a99', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Ahmad Subarjo', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 'Dibatalkan', '', 1111, NULL, '2026-07-07 15:15:17.104737+07');
INSERT INTO public.orders VALUES ('36bd2ed8-0683-4725-a448-3be6538ff37f', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Ahmad Subarjo', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 'Dibatalkan', '', 12000, NULL, '2026-07-02 09:48:53.980977+07');
INSERT INTO public.orders VALUES ('821838c4-bf0b-4342-8601-74196ac0aa0b', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Ahmad Subarjo', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 'Dibatalkan', 'Diantar', 12000, NULL, '2026-07-02 10:40:45.246987+07');
INSERT INTO public.orders VALUES ('a6285ffe-62ba-4dda-8a81-4fbf6ce6b237', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Ahmad Subarjo', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 'Dibatalkan', '', 24000, NULL, '2026-07-02 16:16:40.327154+07');
INSERT INTO public.orders VALUES ('996ae1b8-d350-411f-a514-f0d4eedcb724', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Ahmad Subarjo', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 'Dibatalkan', '', 1111, NULL, '2026-07-08 13:30:14.121516+07');
INSERT INTO public.orders VALUES ('86c21b3e-1430-44a5-947a-b082e50341ab', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Ahmad Subarjo', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 'Dibatalkan', '', 1111, NULL, '2026-07-08 13:26:53.859103+07');
INSERT INTO public.orders VALUES ('93f81b57-f02f-4c78-ba0a-08dca3d6ac56', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Ahmad Subarjo', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 'Dibatalkan', '', 1111, NULL, '2026-07-08 11:59:23.61681+07');
INSERT INTO public.orders VALUES ('fd96944c-0d8b-4ab6-ab6b-e069c8b0166d', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Ahmad Subarjo', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 'Dibatalkan', '', 1111, NULL, '2026-07-08 11:17:34.933842+07');
INSERT INTO public.orders VALUES ('4951234a-3485-463d-ad80-f7ab6834d8a7', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Ahmad Subarjo', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 'Dibatalkan', '', 1111, NULL, '2026-07-08 11:39:45.532596+07');
INSERT INTO public.orders VALUES ('b542f730-3e9d-44e1-922b-30e947373874', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Ahmad Subarjo', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 'Dibatalkan', '', 12000, 'Bahan makanan habis.', '2026-07-03 09:49:52.39106+07');
INSERT INTO public.orders VALUES ('d70280c3-e0a4-4505-b9d1-5f70ca352052', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Ahmad Subarjo', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 'Dibatalkan', '', 1111, NULL, '2026-07-09 09:26:17.706429+07');
INSERT INTO public.orders VALUES ('dedbc144-2cac-40e3-8ae6-b4f015b0f477', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Ahmad Subarjo', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 'Dibatalkan', '', 1111, NULL, '2026-07-09 09:15:56.828631+07');
INSERT INTO public.orders VALUES ('4df1760b-6d9c-4c7d-9e03-dcdcd229aa3e', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Ahmad Subarjo', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 'Dibatalkan', '', 1111, NULL, '2026-07-09 09:14:19.853191+07');
INSERT INTO public.orders VALUES ('4c7165eb-2584-4e36-b37c-6032068f36f8', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Ahmad Subarjo', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 'Dibatalkan', '', 111100, NULL, '2026-07-29 10:22:50.733519+07');
INSERT INTO public.orders VALUES ('c97ac41e-076d-465f-b8a7-898dfd86bf14', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Ahmad Subarjo', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 'Selesai', 'Diantar', 285000, NULL, '2026-07-29 10:25:09.09145+07');
INSERT INTO public.orders VALUES ('2406d7e1-41b3-43e9-80c3-1e52d7bc49f2', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Ahmad Subarjo', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 'Dibatalkan', '', 12000, 'Peralatan memasak mengalami kendala.', '2026-07-03 14:45:44.640781+07');
INSERT INTO public.orders VALUES ('9ae6e66d-b5da-4cb5-9775-937cb3947b0b', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Ahmad Subarjo', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 'Dibatalkan', '', 10231, NULL, '2026-07-29 12:30:06.91418+07');
INSERT INTO public.orders VALUES ('1eeaa248-c001-4136-b646-bbafe82d9c31', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Ahmad Subarjo', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 'Baru', 'Diantar', 5555, NULL, '2026-08-13 14:20:52.43397+07');
INSERT INTO public.orders VALUES ('a038b8aa-c18e-4211-9445-be3f3e1695ea', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Ahmad Subarjo', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 'Baru', 'Diantar', 5555, NULL, '2026-08-13 14:23:04.64457+07');
INSERT INTO public.orders VALUES ('527c5e0b-4ba3-40c7-8829-76334be416d9', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Ahmad Subarjo', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 'Baru', '', 1111, NULL, '2026-08-13 14:25:40.050133+07');
INSERT INTO public.orders VALUES ('a24b6dc5-16e5-4ff4-901f-0d0182ffa66d', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Ahmad Subarjo', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 'Baru', 'Diantar', 3111, NULL, '2026-08-16 11:36:43.168031+07');
INSERT INTO public.orders VALUES ('bd6f4608-db8e-4fa5-8f4f-1fe328567f39', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Ahmad Subarjo', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 'Baru', 'Diantar: <h1>DUAR MEK</h1>', 5000, NULL, '2026-08-20 16:17:32.140836+07');
INSERT INTO public.orders VALUES ('84baa2d0-5ad6-4978-bfb9-b5c84bc18cd7', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Ahmad Subarjo', '98dd238b-b56c-4d27-8125-e0624385d2e7', 'Baru', 'Diantar', 37000, NULL, '2026-08-20 16:23:39.771356+07');
INSERT INTO public.orders VALUES ('330bf1a2-2a47-4414-a520-9352cb42b2f6', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Ahmad Subarjo', '98dd238b-b56c-4d27-8125-e0624385d2e7', 'Baru', 'Diantar', 37000, NULL, '2026-08-20 16:27:13.032939+07');
INSERT INTO public.orders VALUES ('3eb3a9a8-8ea0-4417-8b88-04d9b2a60601', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Ahmad Subarjo', '98dd238b-b56c-4d27-8125-e0624385d2e7', 'Baru', 'Diantar', 7000, NULL, '2026-08-20 16:28:29.319611+07');
INSERT INTO public.orders VALUES ('be752083-bea6-4bfa-a18f-4a36873f8058', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Ahmad Subarjo', '98dd238b-b56c-4d27-8125-e0624385d2e7', 'Baru', 'Dimakan', 7000, NULL, '2026-08-20 16:50:51.208786+07');
INSERT INTO public.orders VALUES ('2f44abc2-29e8-4a66-96bd-dcc2bd3742eb', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Ahmad Subarjo', '98dd238b-b56c-4d27-8125-e0624385d2e7', 'Baru', 'Dimakan', 14000, NULL, '2026-08-20 16:52:28.483044+07');
INSERT INTO public.orders VALUES ('763e2b2f-243f-4872-aebf-c839d192e0e6', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Ahmad Subarjo', '98dd238b-b56c-4d27-8125-e0624385d2e7', 'Baru', 'Dimakan', 14000, NULL, '2026-08-20 16:52:53.36077+07');
INSERT INTO public.orders VALUES ('9454c58d-bfbe-4688-a852-3a80c88987df', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Ahmad Subarjo', '98dd238b-b56c-4d27-8125-e0624385d2e7', 'Baru', 'Dimakan', 14000, NULL, '2026-08-20 16:53:46.494606+07');
INSERT INTO public.orders VALUES ('a84da5ad-2c02-4b09-9173-7a613be06d89', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Ahmad Subarjo', '98dd238b-b56c-4d27-8125-e0624385d2e7', 'Baru', 'Dimakan', 3000, NULL, '2026-08-20 16:53:54.525184+07');
INSERT INTO public.orders VALUES ('f1b15441-2168-45d3-b2d9-23665701eff7', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Ahmad Subarjo', '98dd238b-b56c-4d27-8125-e0624385d2e7', 'Baru', 'Dimakan', 7000, NULL, '2026-08-20 16:54:51.697016+07');
INSERT INTO public.orders VALUES ('ad153ba3-79eb-4e93-8a71-e44432258be1', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Ahmad Subarjo', '98dd238b-b56c-4d27-8125-e0624385d2e7', 'Baru', 'Dimakan', 3000, NULL, '2026-08-20 16:55:17.524647+07');
INSERT INTO public.orders VALUES ('5011f9f5-f9c2-4157-b5ff-8651ab75b0e3', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Ahmad Subarjo', '98dd238b-b56c-4d27-8125-e0624385d2e7', 'Baru', 'Dimakan', 3000, NULL, '2026-08-20 16:55:33.309697+07');
INSERT INTO public.orders VALUES ('416fd98c-adf1-469c-90aa-8c6a6b4c8132', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Ahmad Subarjo', '98dd238b-b56c-4d27-8125-e0624385d2e7', 'Baru', 'Dimakan', 7000, NULL, '2026-08-20 16:56:11.544671+07');
INSERT INTO public.orders VALUES ('eacb4949-4d9e-4938-82eb-1e670c69a965', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Ahmad Subarjo', '98dd238b-b56c-4d27-8125-e0624385d2e7', 'Baru', '', 10, NULL, '2026-08-20 16:56:57.845491+07');
INSERT INTO public.orders VALUES ('bd51b4bc-9168-4bf0-82ce-76c1b338ec18', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Ahmad Subarjo', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 'Selesai', 'Pickup', 30000, NULL, '2026-08-24 10:02:54.656864+07');
INSERT INTO public.orders VALUES ('ddd7eeb2-3c52-458c-8ab7-2e458500c62d', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'Ahmad Subarjo', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 'Siap Diambil', '', 10231, NULL, '2026-08-13 15:09:04.927136+07');
INSERT INTO public.orders VALUES ('4dbec238-d78e-429f-82ce-29471b24e7ab', '90edbc75-8cb8-4e55-8786-e121536cb659', 'Budi Santoso', '45ad99e3-5f4b-42ff-9f84-a85467cbe9b3', 'Selesai', 'Ambil Mandiri (Pickup)', 18000, NULL, '2026-08-27 10:07:31.900614+07');
INSERT INTO public.orders VALUES ('3e327629-6151-4ea3-9e8c-1467017c37da', 'e7925276-2188-4536-b146-73935cea8065', 'Ahmad Fauzi', '45ad99e3-5f4b-42ff-9f84-a85467cbe9b3', 'Selesai', 'Diantar: Kelas XI RPL', 15000, NULL, '2026-08-27 10:07:31.900614+07');
INSERT INTO public.orders VALUES ('1336dc8d-7cea-440c-8d5d-d666c628d15b', 'fc8ac439-1256-468c-8fe3-8fa2e7ff9dcb', 'Rizki Pratama', '51325215-0176-4324-bb74-4e973bcfff13', 'Selesai', 'Ambil Mandiri (Pickup)', 15000, NULL, '2026-08-27 10:07:31.900614+07');
INSERT INTO public.orders VALUES ('e4554553-85d4-4d5b-81af-c0169ca15bfc', 'cd8c7092-f250-49c8-9a66-c4f1c76a2eea', 'azima', '51325215-0176-4324-bb74-4e973bcfff13', 'Selesai', 'Diantar: Lab Komputer 2', 15000, NULL, '2026-08-27 10:07:31.900614+07');


--
-- Data for Name: products; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.products VALUES ('ad805ac8-75b0-4e9c-a055-9abd72a14a38', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 'Nasi Goreng Spesial', 15000, 'makanan', true, 'https://kantin.zitech.web.id/uploads/products/product_nasi_goreng.jpg', '["Pedas Sedang", "Pedas Banget", "Tidak Pedas", "Telur Dadar (+Rp 3.000)"]', '2026-08-27 10:46:03.084377+07', 4.90, 48);
INSERT INTO public.products VALUES ('a30e1a4b-fd91-435d-83db-3959402932bd', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 'Mie Ayam Bakso', 13000, 'makanan', true, 'https://kantin.zitech.web.id/uploads/products/product_mie_ayam.jpg', '["Pangsit Goreng (+Rp 2.000)", "Bakso Tambahan (+Rp 3.000)", "Tanpa Sayur"]', '2026-08-27 10:46:03.084377+07', 4.80, 35);
INSERT INTO public.products VALUES ('f3f402ae-63cb-443c-818e-16fab62a79cf', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 'Ayam Geprek Sambal Ijo', 16000, 'makanan', true, 'https://kantin.zitech.web.id/uploads/products/product_ayam_geprek.jpg', '["Level 1 (Sedang)", "Level 3 (Pedas)", "Level 5 (Super Pedas)", "Ekstra Keju (+Rp 3.000)"]', '2026-08-27 10:46:03.084377+07', 4.90, 52);
INSERT INTO public.products VALUES ('a86158a5-9702-4b1c-a9b0-fa0e2029d749', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 'Bakso Mercon Spesial', 15000, 'makanan', true, 'https://kantin.zitech.web.id/uploads/products/product_bakso_mercon.jpg', '["Kuah Pedas Mercon", "Kuah Bening", "Bihun Ekstra"]', '2026-08-27 10:46:03.084377+07', 4.70, 29);
INSERT INTO public.products VALUES ('97607bc8-c362-4265-a286-bbfecf1605e7', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 'Es Jeruk Segar', 5000, 'minuman', true, 'https://kantin.zitech.web.id/uploads/products/product_es_jeruk.jpg', '["Sedikit Es (Less Ice)", "Tanpa Es", "Gula Sedikit (Less Sugar)"]', '2026-08-27 10:46:03.084377+07', 4.90, 64);
INSERT INTO public.products VALUES ('8db00359-2755-4951-b3cf-37d147f47f47', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 'Es Teh Manis', 3000, 'minuman', true, 'https://kantin.zitech.web.id/uploads/products/product_es_teh.jpg', '["Sedikit Es (Less Ice)", "Manis Sedang", "Tawar Dingin"]', '2026-08-27 10:46:03.084377+07', 4.80, 80);
INSERT INTO public.products VALUES ('e0cd8847-7406-4599-bdbb-66c5806bc6e3', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 'Air Mineral Dingin', 3000, 'minuman', true, 'https://kantin.zitech.web.id/uploads/products/product_air_mineral.jpg', '["Dingin", "Biasa (Suhu Ruang)"]', '2026-08-27 10:46:03.084377+07', 5.00, 95);
INSERT INTO public.products VALUES ('d9795046-f5dc-4871-b369-a2b23b7f2944', '98dd238b-b56c-4d27-8125-e0624385d2e7', 'Soto Ayam Madura', 14000, 'makanan', true, 'https://kantin.zitech.web.id/uploads/products/product_soto_ayam.jpg', '["Koya Banyak", "Jeruk Nipis Tambahan", "Nasi Dipisah (+Rp 3.000)"]', '2026-08-27 10:46:03.093397+07', 5.00, 42);
INSERT INTO public.products VALUES ('03918dfe-c3fa-4519-b8eb-a3bd19732ebe', '98dd238b-b56c-4d27-8125-e0624385d2e7', 'Nasi Rames Komplit', 12000, 'makanan', true, 'https://kantin.zitech.web.id/uploads/products/product_nasi_rames.jpg', '["Lauk Ayam Suwir", "Lauk Telur Balado", "Sambal Goreng Kentang"]', '2026-08-27 10:46:03.093397+07', 4.90, 38);
INSERT INTO public.products VALUES ('78e1ec4f-362e-4ae9-b92c-3a74a8d276ff', '98dd238b-b56c-4d27-8125-e0624385d2e7', 'Dimsum Goreng Hot', 5000, 'camilan', true, 'https://kantin.zitech.web.id/uploads/products/product_dimsum_goreng.jpg', '["Saus Sambal Bangkok", "Mayonaise", "Bubuk Cabe"]', '2026-08-27 10:46:03.093397+07', 5.00, 60);
INSERT INTO public.products VALUES ('01dbd547-d0a9-42f1-b253-898335c274c5', '98dd238b-b56c-4d27-8125-e0624385d2e7', 'Risoles Mayo Crispy', 4000, 'camilan', true, 'https://kantin.zitech.web.id/uploads/products/product_risoles_mayo.jpg', '["Isi Smoked Beef & Telur", "Cabe Rawit Hijau"]', '2026-08-27 10:46:03.093397+07', 4.80, 31);
INSERT INTO public.products VALUES ('5db939da-0420-4d45-9e9e-e8a50c7bd7ef', '45ad99e3-5f4b-42ff-9f84-a85467cbe9b3', 'Bakso Urat Komplit', 18000, 'makanan', true, 'https://kantin.zitech.web.id/uploads/products/product_bakso_mercon.jpg', '["Campur Mie & Bihun", "Bihun Saja", "Mie Kuning Saja"]', '2026-08-27 10:46:03.095658+07', 4.80, 27);
INSERT INTO public.products VALUES ('40671946-314a-4df1-9608-d71d74455b61', '45ad99e3-5f4b-42ff-9f84-a85467cbe9b3', 'Mie Bakso Urat', 15000, 'makanan', true, 'https://kantin.zitech.web.id/uploads/products/product_mie_ayam.jpg', '["Pedas", "Sedang", "Kuah Bening"]', '2026-08-27 10:46:03.095658+07', 4.60, 22);
INSERT INTO public.products VALUES ('9db00708-26b6-4ccf-b7f8-25bd3f4e999a', '51325215-0176-4324-bb74-4e973bcfff13', 'Nasi Goreng Pedas Gila', 14000, 'makanan', true, 'https://kantin.zitech.web.id/uploads/products/product_nasi_goreng.jpg', '["Level 1", "Level 2", "Level 3 Gila", "Telur Ceplok (+Rp 3.000)"]', '2026-08-27 10:46:03.097265+07', 4.70, 33);
INSERT INTO public.products VALUES ('8e0f9715-4809-467a-84a3-e1f98f12a561', '51325215-0176-4324-bb74-4e973bcfff13', 'Pisang Goreng Keju', 6000, 'camilan', true, 'https://kantin.zitech.web.id/uploads/products/product_pisang_keju.jpg', '["Cokelat Keju", "Keju Susu", "Original Crispy"]', '2026-08-27 10:46:03.097265+07', 4.90, 45);
INSERT INTO public.products VALUES ('a5029eee-e60b-4cf5-94e5-4ca693c35bbf', '51325215-0176-4324-bb74-4e973bcfff13', 'Tango Wafer Cokelat', 7000, 'camilan', true, 'https://kantin.zitech.web.id/uploads/products/product_tango_wafer.jpg', '["Wafer Cokelat", "Wafer Vanila"]', '2026-08-27 10:46:03.097265+07', 4.50, 19);
INSERT INTO public.products VALUES ('1eb4af50-9a49-468b-9e9b-10f42f95cded', '51325215-0176-4324-bb74-4e973bcfff13', 'Jus Alpukat Kocok', 8000, 'minuman', true, 'https://kantin.zitech.web.id/uploads/products/product_jus_alpukat.jpg', '["Susu Cokelat", "Susu Putih", "Gula Sedikit"]', '2026-08-27 10:46:03.097265+07', 4.90, 57);


--
-- Data for Name: order_items; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.order_items VALUES ('43b95cea-18de-4141-9246-3417ca2710e5', '2f44abc2-29e8-4a66-96bd-dcc2bd3742eb', 'Dimsum Goreng Hots', 1, 12000, '[]', '', NULL);
INSERT INTO public.order_items VALUES ('a738698e-d29d-4201-91d7-3fdb463d9a1a', '763e2b2f-243f-4872-aebf-c839d192e0e6', 'Masa?', 1, 12000, '[]', '', NULL);
INSERT INTO public.order_items VALUES ('02ad92c1-826a-4c26-9bcb-bb2d9b08b395', '9454c58d-bfbe-4688-a852-3a80c88987df', 'Masa?', 1, 12000, '[]', '', NULL);
INSERT INTO public.order_items VALUES ('434ee43b-fa25-42c4-8ce0-af292d5d6aa5', 'a84da5ad-2c02-4b09-9173-7a613be06d89', 'Masa?', 1, 1000, '[]', '', NULL);
INSERT INTO public.order_items VALUES ('0396110a-6faf-42e8-a775-99285364fff5', 'ad153ba3-79eb-4e93-8a71-e44432258be1', 'Ayam Bakar Pak Lurah', 1, 1000, '[]', '', NULL);
INSERT INTO public.order_items VALUES ('858eed0d-abc0-4f59-a4d4-6cc65485f4e7', '5011f9f5-f9c2-4157-b5ff-8651ab75b0e3', 'Dimsum Goreng Hot ', 1, 1000, '[]', '', NULL);
INSERT INTO public.order_items VALUES ('b517d1f5-9105-4fb6-96e6-a286a4553971', 'eacb4949-4d9e-4938-82eb-1e670c69a965', 'Dimsum Goreng Hot ', 1, 10, '[]', '', NULL);
INSERT INTO public.order_items VALUES ('ce8dd9a8-a58c-44f6-b877-b1a444b2e9ff', '416fd98c-adf1-469c-90aa-8c6a6b4c8132', 'Dimsum Goreng Hot', 1, 5000, '[]', '', NULL);
INSERT INTO public.order_items VALUES ('36f0f724-a2fa-4a71-8d16-2acdcea761da', 'f1b15441-2168-45d3-b2d9-23665701eff7', 'Dimsum Goreng Hot', 1, 5000, '[]', '', NULL);
INSERT INTO public.order_items VALUES ('24d55a90-3c00-499e-8b29-17925dcf41eb', 'be752083-bea6-4bfa-a18f-4a36873f8058', 'Dimsum Goreng Hot', 1, 5000, '[]', '', NULL);
INSERT INTO public.order_items VALUES ('3d333f25-7d5b-44ef-8dc5-96adc316d89d', '3eb3a9a8-8ea0-4417-8b88-04d9b2a60601', 'Dimsum Goreng Hot', 1, 5000, '[]', '', NULL);
INSERT INTO public.order_items VALUES ('c09bb6ed-84ec-446f-9544-05a3ab679727', '330bf1a2-2a47-4414-a520-9352cb42b2f6', 'Dimsum Goreng Hot', 7, 5000, '[]', '', NULL);
INSERT INTO public.order_items VALUES ('457ed43a-f016-4968-b394-d0a03332111e', '84baa2d0-5ad6-4978-bfb9-b5c84bc18cd7', 'Dimsum Goreng Hot', 7, 5000, '[]', '', NULL);
INSERT INTO public.order_items VALUES ('1d3ed233-634c-4717-8f2d-dcd4e1cd6dc8', 'a24b6dc5-16e5-4ff4-901f-0d0182ffa66d', 'aaa', 1, 1111, '[]', NULL, NULL);
INSERT INTO public.order_items VALUES ('49b299a4-0edd-4e2a-95e6-c3c82ae028fd', '527c5e0b-4ba3-40c7-8829-76334be416d9', 'aaa', 1, 1111, '[]', NULL, NULL);
INSERT INTO public.order_items VALUES ('dac61316-4dfd-4317-9ff9-a5b8babf9223', 'a038b8aa-c18e-4211-9445-be3f3e1695ea', 'aaa', 5, 1111, '[]', NULL, NULL);
INSERT INTO public.order_items VALUES ('833574bd-a99b-499a-a9db-efa1337ee3a2', '1eeaa248-c001-4136-b646-bbafe82d9c31', 'aaa', 5, 1111, '[]', NULL, NULL);
INSERT INTO public.order_items VALUES ('38872fc5-df25-43ac-aad2-ec5c15eb1dd2', '4c7165eb-2584-4e36-b37c-6032068f36f8', 'aaa', 100, 1111, '[]', NULL, NULL);
INSERT INTO public.order_items VALUES ('1eec1804-33f2-4b10-b8b3-1d79f043f222', 'd70280c3-e0a4-4505-b9d1-5f70ca352052', 'aaa', 1, 1111, '[]', NULL, NULL);
INSERT INTO public.order_items VALUES ('d1aeb2d3-53d4-4b9e-8061-ecaf8df91f3d', 'dedbc144-2cac-40e3-8ae6-b4f015b0f477', 'aaa', 1, 1111, '[]', NULL, NULL);
INSERT INTO public.order_items VALUES ('f442d67a-f2e3-4b54-836e-2f75f5265a40', '4df1760b-6d9c-4c7d-9e03-dcdcd229aa3e', 'aaa', 1, 1111, '[]', NULL, NULL);
INSERT INTO public.order_items VALUES ('ff647589-96ec-498e-87fa-a935fe7eea69', '996ae1b8-d350-411f-a514-f0d4eedcb724', 'aaa', 1, 1111, '[]', NULL, NULL);
INSERT INTO public.order_items VALUES ('3bd9c275-4b1c-4e60-8ba6-34a60eea9a75', '86c21b3e-1430-44a5-947a-b082e50341ab', 'aaa', 1, 1111, '[]', NULL, NULL);
INSERT INTO public.order_items VALUES ('c1b3c5c2-ca78-41b2-b258-8f5438b349fc', '93f81b57-f02f-4c78-ba0a-08dca3d6ac56', 'aaa', 1, 1111, '[]', NULL, NULL);
INSERT INTO public.order_items VALUES ('237891a1-6c8b-486e-86cc-9ca57fd0761b', '4951234a-3485-463d-ad80-f7ab6834d8a7', 'aaa', 1, 1111, '[]', NULL, NULL);
INSERT INTO public.order_items VALUES ('449964a6-f4d8-4509-86fd-71cc9d712038', 'fd96944c-0d8b-4ab6-ab6b-e069c8b0166d', 'aaa', 1, 1111, '[]', NULL, NULL);
INSERT INTO public.order_items VALUES ('3b25bc43-aedc-488f-badd-b4b6356b4d35', '4c3179f9-eca8-40a9-b356-1bebb10a0eb7', 'aaa', 1, 1111, '[]', NULL, NULL);
INSERT INTO public.order_items VALUES ('a81b4f21-8222-47ec-a89b-345455fb6629', 'b915d63d-1008-4f5f-bed5-4cd84c8d61c7', 'aaa', 1, 1111, '[]', NULL, NULL);
INSERT INTO public.order_items VALUES ('4d774028-c7da-4a0f-9572-439312acac02', '1a479765-0bea-4e57-87ce-43a7ec9e1516', 'aaa', 1, 1111, '[]', NULL, NULL);
INSERT INTO public.order_items VALUES ('293d581d-8a95-40e9-8b87-48097b4f7db7', 'faaebebf-61cd-416a-a50e-3b63a4392a99', 'aaa', 1, 1111, '[]', NULL, NULL);
INSERT INTO public.order_items VALUES ('9e3b4cd9-6ba1-4051-b2e5-320319b44f63', 'ddd7eeb2-3c52-458c-8ab7-2e458500c62d', 'cemil', 1, 10231, '[]', NULL, NULL);
INSERT INTO public.order_items VALUES ('47f9e2c6-73bd-4443-a2b8-01fd871e5f46', '9ae6e66d-b5da-4cb5-9775-937cb3947b0b', 'cemil', 1, 10231, '[]', NULL, NULL);
INSERT INTO public.order_items VALUES ('1a44df88-836a-4a36-a0c5-cabaeb7055f1', 'bd6f4608-db8e-4fa5-8f4f-1fe328567f39', 'aqua', 1, 3000, '[]', '', NULL);
INSERT INTO public.order_items VALUES ('d00b1dc8-16d8-4b51-a247-4e01ad1159a9', 'c97ac41e-076d-465f-b8a7-898dfd86bf14', 'nasgor goreng pedes', 15, 19000, '["sambal (Level 3 🌶️🌶️🌶️)", "timun", "tomat", "telur (+Rp 3.000) (1x)", "sosis (+Rp 1.000) (1x)", "ayam (33x)"]', NULL, NULL);
INSERT INTO public.order_items VALUES ('5bd3b2f9-7ade-445f-8873-df2507992863', 'bd51b4bc-9168-4bf0-82ce-76c1b338ec18', 'Bakso Mercon Spesial', 2, 15000, 'null', '', NULL);
INSERT INTO public.order_items VALUES ('46ac488f-70af-49b1-a3cb-7a0c255abba8', '6a7a00b2-9215-44a8-b3d6-54fefeb21070', 'nasgor goreng pedes', 1, 12000, '["Sambal (Level 3)", "timun", "telur (1x)", "sosis (1x)"]', NULL, NULL);
INSERT INTO public.order_items VALUES ('a8387c73-ac7e-4b71-aca0-a4232a13d4fd', 'f76f8d07-ac8e-4888-902b-bddbec5f7674', 'nasgor goreng pedes', 1, 12000, '["Sambal (Level 3)", "tomat", "telur (4x)", "sosis (3x)"]', NULL, NULL);
INSERT INTO public.order_items VALUES ('c52cc35a-75bd-427f-aeef-090eeacbfa55', 'f9aa1d8b-cf16-4572-b8ba-c0dc63201505', 'nasgor goreng pedes', 1, 12000, '["Sambal (Level 1)"]', NULL, NULL);
INSERT INTO public.order_items VALUES ('594237d3-a92f-461e-a1d6-783ed4c31ec7', '71cf0c81-aa1d-4a35-b6bb-aed0e5c30960', 'nasgor goreng pedes', 1, 12000, '["Sambal (Level 3)", "tomat", "telur (1x)"]', NULL, NULL);
INSERT INTO public.order_items VALUES ('775f8f6e-ea44-4229-ada7-2e781851e220', '2406d7e1-41b3-43e9-80c3-1e52d7bc49f2', 'nasgor goreng pedes', 1, 12000, '["Sambal (Level 2)", "tomat", "telur (1x)"]', NULL, NULL);
INSERT INTO public.order_items VALUES ('83061f2a-9c7e-4c68-bfcf-94fb834035f0', 'b542f730-3e9d-44e1-922b-30e947373874', 'nasgor goreng pedes', 1, 12000, '["Sambal (Level 2)", "tomat", "telur (1x)", "ayam (1x)"]', NULL, NULL);
INSERT INTO public.order_items VALUES ('911e87ee-0d93-4612-a4a2-1ee845a5d7c6', 'a6285ffe-62ba-4dda-8a81-4fbf6ce6b237', 'nasgor goreng pedes', 1, 12000, '["Sambal (Level 2)", "tomat", "bakso (2x)", "sosis (2x)"]', NULL, NULL);
INSERT INTO public.order_items VALUES ('eee3f73c-dd81-418f-9268-43670db16bff', 'a6285ffe-62ba-4dda-8a81-4fbf6ce6b237', 'nasgor goreng pedes', 1, 12000, '["Sambal (Level 3)", "tomat", "ayam (1x)"]', NULL, NULL);
INSERT INTO public.order_items VALUES ('7df62139-a70a-452d-a6e9-2cf4cc2b6a35', '821838c4-bf0b-4342-8601-74196ac0aa0b', 'nasgor goreng pedes', 1, 12000, '["Sambal (Level 2)", "timun", "tomat", "bakso (1x)"]', NULL, NULL);
INSERT INTO public.order_items VALUES ('98173805-fc3d-4804-81f4-8e4e0b1b51fd', '36bd2ed8-0683-4725-a448-3be6538ff37f', 'nasgor goreng pedes', 1, 12000, '["Sambal (Level 1)"]', NULL, NULL);
INSERT INTO public.order_items VALUES ('6b0de0ca-2fc3-455f-b8df-1fde6a31d13f', '7f43d5f2-11f8-4c62-b6fc-00a69c47ae99', 'nasgor goreng pedes', 1, 12000, '["Sambal (Level 2)", "bakso (1x)"]', NULL, NULL);
INSERT INTO public.order_items VALUES ('e71dc450-8ba9-43ef-aae3-48e96b9bc706', 'cf6e5023-6ca8-4248-a87f-90ae6639806d', 'nasgor goreng pedes', 1, 12000, '["Sambal (Level 3)", "timun", "telur (1x)", "bakso (3x)", "ayam (1x)"]', NULL, NULL);
INSERT INTO public.order_items VALUES ('0622e4bc-7aa9-47a3-ad78-5bf5e34acc6d', '885f8570-a3ee-400a-83ff-32e6d6f84e54', 'nasgor goreng pedes', 1, 12000, '["Sambal (Level 3)", "tomat", "sosis (1x)", "ayam (1x)"]', NULL, NULL);
INSERT INTO public.order_items VALUES ('20927560-26ed-45ae-8654-52a5a15f225d', '885f8570-a3ee-400a-83ff-32e6d6f84e54', 'nasgor goreng pedes', 1, 12000, '["Sambal (Level 1)", "timun", "tomat", "telur (1x)", "sosis (1x)"]', NULL, NULL);


--
-- Data for Name: order_messages; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.order_messages VALUES ('a57e2376-6b24-4038-93b6-335d8d2ee241', 'c97ac41e-076d-465f-b8a7-898dfd86bf14', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'student', 'Apa', '2026-08-24 15:09:42.882866+07', false);
INSERT INTO public.order_messages VALUES ('7dd4f77e-07bf-4dcd-ad2d-a1682c2c4c84', 'c97ac41e-076d-465f-b8a7-898dfd86bf14', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'student', 'bangsay', '2026-08-24 15:09:52.118898+07', false);
INSERT INTO public.order_messages VALUES ('0e50528b-fc8b-4fc1-acb7-8e4f611ee352', '4c7165eb-2584-4e36-b37c-6032068f36f8', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'student', 'Saya mau ambil jam istirahat ya', '2026-08-24 15:10:33.266443+07', false);
INSERT INTO public.order_messages VALUES ('a7f3f3ce-b025-4d73-b651-e7c4c1bdbd90', 'bd51b4bc-9168-4bf0-82ce-76c1b338ec18', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'student', 'Pesanan saya sudah sampai mana ya?', '2026-08-27 09:56:44.456713+07', true);
INSERT INTO public.order_messages VALUES ('364c7362-d20c-4943-8096-f92f8fe6e077', 'bd51b4bc-9168-4bf0-82ce-76c1b338ec18', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'student', 'Pesanan saya sudah sampai mana ya?', '2026-08-27 09:56:44.480706+07', true);
INSERT INTO public.order_messages VALUES ('e6b4c96e-664b-460a-a898-61d13d4c4b6c', 'bd51b4bc-9168-4bf0-82ce-76c1b338ec18', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'student', 'Tolong dipisah sambalnya ya kak', '2026-08-27 09:56:47.780232+07', true);


--
-- Data for Name: order_reviews; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.order_reviews VALUES ('e19be040-e2b6-4c7e-93a7-c412945c898d', '71cf0c81-aa1d-4a35-b6bb-aed0e5c30960', 'e7925276-2188-4536-b146-73935cea8065', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 5, 'Nasi goreng spesialnya enak banget, porsi pas dan sambalnya mantap!', '{"Enak Banget","Porsi Pas","Sambal Juara"}', false, '2026-08-25 10:07:31.900614+07');
INSERT INTO public.order_reviews VALUES ('8cc35cff-61ea-4ff1-b769-755bf994c573', '885f8570-a3ee-400a-83ff-32e6d6f84e54', '87c5bfac-fb35-40c6-bb9a-9b0f969d6ae4', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 5, 'Pelayanan cepat dan ramah, es jeruknya segar alami tanpa pemanis buatan.', '{"Pelayanan Cepat","Segar Alami"}', false, '2026-08-26 10:07:31.900614+07');
INSERT INTO public.order_reviews VALUES ('e58e7000-ad2b-472c-9f88-cac29cad68ae', 'cf6e5023-6ca8-4248-a87f-90ae6639806d', '90edbc75-8cb8-4e55-8786-e121536cb659', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 4, 'Ayam gepreknya renyah, bumbu sambal ijonya meresap enak.', '{Renyah,"Pedas Mantap"}', false, '2026-08-27 05:07:31.900614+07');
INSERT INTO public.order_reviews VALUES ('ba9adccb-d806-4429-a60d-4a69b2ee9014', 'c97ac41e-076d-465f-b8a7-898dfd86bf14', 'fc8ac439-1256-468c-8fe3-8fa2e7ff9dcb', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 5, 'Mie ayam bakso kuahnya gurih kaya rempah, langganan tiap istirahat!', '{"Kuah Gurih",Rekomendasi}', false, '2026-08-27 09:07:31.900614+07');
INSERT INTO public.order_reviews VALUES ('850aa232-d7c7-4fc6-aa52-7885e80fbe1d', '84baa2d0-5ad6-4978-bfb9-b5c84bc18cd7', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '98dd238b-b56c-4d27-8125-e0624385d2e7', 5, 'Soto ayam madura bude kuahnya rempah asli, koya-nya melimpah!', '{"Rempah Asli","Porsi Banyak"}', false, '2026-08-24 10:07:31.900614+07');
INSERT INTO public.order_reviews VALUES ('025a7833-cfa0-4b41-8538-ce8ae09f277a', '330bf1a2-2a47-4414-a520-9352cb42b2f6', 'cd8c7092-f250-49c8-9a66-c4f1c76a2eea', '98dd238b-b56c-4d27-8125-e0624385d2e7', 5, 'Nasi rames bude lauknya komplit, bersih dan selalu hangat saat diantar.', '{"Lauk Komplit","Bersih & Rapi"}', false, '2026-08-26 10:07:31.900614+07');
INSERT INTO public.order_reviews VALUES ('cbe3c920-d4f6-47ef-a660-26b54bd30d01', '3eb3a9a8-8ea0-4417-8b88-04d9b2a60601', '87c5bfac-fb35-40c6-bb9a-9b0f969d6ae4', '98dd238b-b56c-4d27-8125-e0624385d2e7', 5, 'Dimsum goreng hot crispy banget, saus cocolannya juara di kantin.', '{Crispy,"Saus Enak"}', false, '2026-08-27 08:07:31.900614+07');
INSERT INTO public.order_reviews VALUES ('db6aee73-81ab-4ba5-ba0c-d09f2b01fecf', '4dbec238-d78e-429f-82ce-29471b24e7ab', '90edbc75-8cb8-4e55-8786-e121536cb659', '45ad99e3-5f4b-42ff-9f84-a85467cbe9b3', 5, 'Bakso uratnya kerasa daging aslinya, kuah kaldunya gurih hangat mantap.', '{"Daging Asli","Kuah Kaldu"}', false, '2026-08-25 10:07:31.900614+07');
INSERT INTO public.order_reviews VALUES ('cd4fce46-ce90-4e16-b045-7cb614890491', '3e327629-6151-4ea3-9e8c-1467017c37da', 'e7925276-2188-4536-b146-73935cea8065', '45ad99e3-5f4b-42ff-9f84-a85467cbe9b3', 4, 'Mie bakso spesial porsi mengenyangkan, harga sangat pas untuk kantong sekolah.', '{Kenyang,"Harga Pelajar"}', false, '2026-08-27 06:07:31.900614+07');
INSERT INTO public.order_reviews VALUES ('72ad1897-73d8-414b-a325-9f9c97b1fabc', '1336dc8d-7cea-440c-8d5d-d666c628d15b', 'fc8ac439-1256-468c-8fe3-8fa2e7ff9dcb', '51325215-0176-4324-bb74-4e973bcfff13', 5, 'Nasgor goreng pedes beneran pedas mantap bikin nagih, recommended!', '{"Pedas Mantap","Wajib Coba"}', false, '2026-08-26 10:07:31.900614+07');
INSERT INTO public.order_reviews VALUES ('625dd2d7-937d-43b3-bc4f-a04ecaf05d47', 'e4554553-85d4-4d5b-81af-c0169ca15bfc', 'cd8c7092-f250-49c8-9a66-c4f1c76a2eea', '51325215-0176-4324-bb74-4e973bcfff13', 4, 'Bumbu nasgor meresap dan telur ceploknya pas matangnya.', '{"Bumbu Enak"}', false, '2026-08-27 07:07:31.900614+07');


--
-- Data for Name: parent_students; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.parent_students VALUES ('be6b25ff-71ab-445e-a6be-0c96173ce17a', '6a4e32d5-45c1-4b10-86d9-f5d60b571111', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '2026-06-17 11:41:33.797819+07');
INSERT INTO public.parent_students VALUES ('4e0f93df-518d-4b00-950f-7c3a9a6ea894', '92e9992f-d627-4070-b2e7-38905d934814', '90edbc75-8cb8-4e55-8786-e121536cb659', '2026-06-19 16:01:40.040958+07');
INSERT INTO public.parent_students VALUES ('be0d598f-8a88-4a7d-a7de-2a9b3dbaa52d', 'e19a8524-9b2a-4ae8-a177-62c21760e70b', 'e7925276-2188-4536-b146-73935cea8065', '2026-06-19 16:01:40.040958+07');
INSERT INTO public.parent_students VALUES ('dd4c163c-abcf-46e9-afe8-f0c38cf696a7', '37e22cf7-173c-4351-b766-24574e25a630', '225883f2-5a0c-4228-89c3-7fca0dff4221', '2026-06-19 16:01:40.040958+07');
INSERT INTO public.parent_students VALUES ('100cc922-9af9-4bc6-bc75-9c6842294878', 'b68788d2-6643-4310-a18f-723d11a7b1d9', '87c5bfac-fb35-40c6-bb9a-9b0f969d6ae4', '2026-06-19 16:01:40.040958+07');
INSERT INTO public.parent_students VALUES ('e6475ab3-94b4-4369-a8c4-69be62c0192e', 'd511689b-7ae6-4fb1-bbbd-e5d4ec35d9ca', 'dfee7423-df2d-4ea9-ac9a-0df4af6b5496', '2026-06-19 16:01:40.040958+07');


--
-- Data for Name: students; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.students VALUES ('225883f2-5a0c-4228-89c3-7fca0dff4221', 0, NULL, false, NULL, true, NULL, 'af07626a-0fe9-4b90-a525-1e4d207ccf53', '75bd9177-1c3d-4b6d-871b-baef0eb5e546', 'X RPL 1', 'X RPL 1');
INSERT INTO public.students VALUES ('dfee7423-df2d-4ea9-ac9a-0df4af6b5496', 0, NULL, false, NULL, true, NULL, 'af07626a-0fe9-4b90-a525-1e4d207ccf53', '75bd9177-1c3d-4b6d-871b-baef0eb5e546', 'X RPL 1', 'X RPL 1');
INSERT INTO public.students VALUES ('87c5bfac-fb35-40c6-bb9a-9b0f969d6ae4', 0, NULL, false, NULL, true, NULL, 'af07626a-0fe9-4b90-a525-1e4d207ccf53', '3bcd9268-c1d2-4d24-aefd-916ce3d89acb', 'X RPL 1', 'X RPL 1');
INSERT INTO public.students VALUES ('90edbc75-8cb8-4e55-8786-e121536cb659', 0, NULL, true, NULL, true, NULL, '6410b488-b7c9-4bf8-9d15-a43df8670f3a', '75bd9177-1c3d-4b6d-871b-baef0eb5e546', 'X RPL 1', 'X RPL 1');
INSERT INTO public.students VALUES ('fc8ac439-1256-468c-8fe3-8fa2e7ff9dcb', 0, NULL, true, 0, true, NULL, NULL, NULL, 'XII RPL 1', 'XII RPL 1');
INSERT INTO public.students VALUES ('e7925276-2188-4536-b146-73935cea8065', 40000, 'AB:FD:06:0A', true, 0, true, NULL, 'af07626a-0fe9-4b90-a525-1e4d207ccf53', '75bd9177-1c3d-4b6d-871b-baef0eb5e546', 'X RPL 1', 'X RPL 1');
INSERT INTO public.students VALUES ('cd8c7092-f250-49c8-9a66-c4f1c76a2eea', 20000, '1111111', true, 0, true, NULL, NULL, NULL, 'X TKJ 2', 'X TKJ 2');
INSERT INTO public.students VALUES ('03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 26990, '04:A3:F8:12', true, 100000, true, NULL, NULL, NULL, 'X RPL 1', 'X RPL 1');


--
-- Data for Name: system_settings; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.system_settings VALUES ('academic_structure', '{"majors": [{"id": "rpl", "code": "RPL", "name": "Rekayasa Perangkat Lunak"}, {"id": "tkj", "code": "TKJ", "name": "Teknik Komputer & Jaringan"}, {"id": "dkv", "code": "DKV", "name": "Desain Komunikasi Visual"}, {"id": "akl", "code": "AKL", "name": "Akuntansi & Keuangan Lembaga"}, {"id": "otkp", "code": "OTKP", "name": "Otomatisasi & Tata Kelola Perkantoran"}], "rombels": ["X RPL 1", "X RPL 2", "X TKJ 1", "X TKJ 2", "X DKV 1", "X AKL 1", "XI RPL 1", "XI RPL 2", "XI TKJ 1", "XI TKJ 2", "XI DKV 1", "XI AKL 1", "XII RPL 1", "XII RPL 2", "XII TKJ 1", "XII TKJ 2", "XII DKV 1", "XII AKL 1"], "has_majors": true, "updated_at": "2026-08-20T15:34:32.189309975+07:00", "school_name": "SMK Negeri 1", "school_type": "smk", "grade_levels": ["X", "XI", "XII"]}', 'Pengaturan master struktur jenjang, jurusan, kelas, dan rombel sekolah', '2026-08-20 15:34:32.190302+07');
INSERT INTO public.system_settings VALUES ('maintenance_mode', 'true', NULL, '2026-08-24 13:48:29.02489+07');
INSERT INTO public.system_settings VALUES ('midtrans_config', '{"mode": "sandbox", "is_active": true, "client_key": "SB-Mid-client-1234567890", "server_key": "SB-Mid-server-1234567890", "merchant_id": "G123456"}', NULL, '2026-08-24 13:48:29.02642+07');


--
-- Data for Name: transactions; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.transactions VALUES ('6a824fec-f08e-4227-a5ac-e487f77b22fd', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 10000, 'topup', 'success', 'rfid', '2026-06-15 12:39:05.285815+07');
INSERT INTO public.transactions VALUES ('9583ff88-a948-4cb5-a71f-61d9fb7fcf22', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 50000, 'topup', 'success', 'rfid', '2026-06-17 14:34:46.666139+07');
INSERT INTO public.transactions VALUES ('838a5981-a945-4498-8c33-0c0be48db0a9', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 500000, 'topup', 'success', 'rfid', '2026-06-17 16:42:05.492171+07');
INSERT INTO public.transactions VALUES ('79d7ced8-dae9-4f8b-a48a-591127dd2890', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 500000, 'topup', 'success', 'rfid', '2026-06-17 16:42:12.968463+07');
INSERT INTO public.transactions VALUES ('4e0bcde2-5ea6-43c5-82bb-41678d480174', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 500000, 'topup', 'success', 'rfid', '2026-06-17 16:42:35.221497+07');
INSERT INTO public.transactions VALUES ('cd09ab77-0314-4848-af3a-1476659051fe', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 500000, 'topup', 'success', 'rfid', '2026-06-17 16:44:10.759313+07');
INSERT INTO public.transactions VALUES ('1e381bc0-6de2-4b70-9f89-4a1e12546894', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 50000, 'topup', 'success', 'rfid', '2026-06-19 09:57:31.709772+07');
INSERT INTO public.transactions VALUES ('45181373-e92e-4f0b-97a8-041528379a30', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 18500, 'purchase', 'success', 'rfid', '2026-06-24 11:55:37.779002+07');
INSERT INTO public.transactions VALUES ('fd020f30-cee1-4b31-a9b9-5d1b2bbdf8f2', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '45ad99e3-5f4b-42ff-9f84-a85467cbe9b3', 20000, 'topup', 'success', 'rfid', '2026-06-29 14:54:15.732268+07');
INSERT INTO public.transactions VALUES ('c10a984d-4a58-49c5-8d73-c23942470fac', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '45ad99e3-5f4b-42ff-9f84-a85467cbe9b3', 20000, 'topup', 'success', 'rfid', '2026-06-29 15:21:05.291051+07');
INSERT INTO public.transactions VALUES ('05399dd3-da4e-4711-be11-4f776ae20d9e', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '45ad99e3-5f4b-42ff-9f84-a85467cbe9b3', 20000, 'topup', 'success', 'rfid', '2026-06-29 15:21:22.841848+07');
INSERT INTO public.transactions VALUES ('e2c367e5-99ba-4a18-9de9-275cab61dba9', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '45ad99e3-5f4b-42ff-9f84-a85467cbe9b3', 20000, 'topup', 'success', 'rfid', '2026-06-29 15:21:35.881579+07');
INSERT INTO public.transactions VALUES ('28eb36ec-b11c-4c92-8897-c859d9d2893c', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '45ad99e3-5f4b-42ff-9f84-a85467cbe9b3', 20000, 'topup', 'success', 'rfid', '2026-06-29 15:24:38.540967+07');
INSERT INTO public.transactions VALUES ('c837fade-f1d9-4227-89f9-d349748c31f6', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '45ad99e3-5f4b-42ff-9f84-a85467cbe9b3', 20000, 'topup', 'success', 'rfid', '2026-06-29 15:24:49.375671+07');
INSERT INTO public.transactions VALUES ('c8180060-e375-440f-8e45-1834bbbd64eb', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '45ad99e3-5f4b-42ff-9f84-a85467cbe9b3', 20000, 'topup', 'success', 'rfid', '2026-06-29 15:27:47.700078+07');
INSERT INTO public.transactions VALUES ('2c21675e-29d6-48fb-859c-c07ba8f3c5d2', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '45ad99e3-5f4b-42ff-9f84-a85467cbe9b3', 20000, 'topup', 'success', 'rfid', '2026-06-29 15:28:00.131241+07');
INSERT INTO public.transactions VALUES ('223d5b90-2488-43b0-aa5c-c77bfffa53c8', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '45ad99e3-5f4b-42ff-9f84-a85467cbe9b3', 20000, 'topup', 'success', 'rfid', '2026-06-29 15:28:10.298204+07');
INSERT INTO public.transactions VALUES ('c179a99f-ea61-4c5f-a4a9-4c3c6eb1ca2f', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '45ad99e3-5f4b-42ff-9f84-a85467cbe9b3', 20000, 'topup', 'success', 'rfid', '2026-06-29 15:33:45.314516+07');
INSERT INTO public.transactions VALUES ('01934cd5-5ccf-4380-ac67-38da2c35b10b', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '45ad99e3-5f4b-42ff-9f84-a85467cbe9b3', 20000, 'topup', 'success', 'rfid', '2026-06-29 15:52:14.09688+07');
INSERT INTO public.transactions VALUES ('f0fcf24e-c100-4f23-996d-63850e40882b', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '45ad99e3-5f4b-42ff-9f84-a85467cbe9b3', 20000, 'topup', 'success', 'rfid', '2026-06-29 15:52:14.096706+07');
INSERT INTO public.transactions VALUES ('734f3326-74b0-471b-9cba-520a90ce341a', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '45ad99e3-5f4b-42ff-9f84-a85467cbe9b3', 20000, 'topup', 'success', 'rfid', '2026-06-29 16:00:31.274331+07');
INSERT INTO public.transactions VALUES ('469a4168-ed17-4f1e-88ff-8521c8ccb60a', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '45ad99e3-5f4b-42ff-9f84-a85467cbe9b3', 20000, 'topup', 'success', 'rfid', '2026-06-29 16:00:41.631568+07');
INSERT INTO public.transactions VALUES ('1d80635f-e989-49d0-80d4-f8f590fc53ac', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '45ad99e3-5f4b-42ff-9f84-a85467cbe9b3', 20000, 'topup', 'success', 'rfid', '2026-06-29 16:00:55.97367+07');
INSERT INTO public.transactions VALUES ('bde1531c-3c18-4055-8925-125e9af5f828', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '45ad99e3-5f4b-42ff-9f84-a85467cbe9b3', 20000, 'topup', 'success', 'rfid', '2026-06-29 16:09:47.926406+07');
INSERT INTO public.transactions VALUES ('5735bd40-0918-4108-bb8f-2e675654ae00', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '45ad99e3-5f4b-42ff-9f84-a85467cbe9b3', 10000, 'topup', 'success', 'rfid', '2026-06-29 16:29:42.738759+07');
INSERT INTO public.transactions VALUES ('2ce026ba-3afd-4f85-8edd-b68c1e912d56', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '45ad99e3-5f4b-42ff-9f84-a85467cbe9b3', 100000, 'topup', 'success', 'rfid', '2026-06-29 16:37:05.086685+07');
INSERT INTO public.transactions VALUES ('d9ee7980-713d-49f1-aab9-3fe68c3399d8', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '45ad99e3-5f4b-42ff-9f84-a85467cbe9b3', 100000, 'topup', 'success', 'rfid', '2026-06-29 16:37:46.271542+07');
INSERT INTO public.transactions VALUES ('612b94b0-6cdb-4103-b7ff-e9433ec65c4a', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '45ad99e3-5f4b-42ff-9f84-a85467cbe9b3', 100000, 'topup', 'success', 'rfid', '2026-06-29 16:42:18.396683+07');
INSERT INTO public.transactions VALUES ('80a92961-f006-4cbc-85c4-acf1438ee283', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 24000, 'purchase', 'success', 'rfid', '2026-07-01 11:29:49.026315+07');
INSERT INTO public.transactions VALUES ('34cfd397-23a9-4491-b7cc-b191bbb241d4', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 12000, 'purchase', 'success', 'rfid', '2026-07-01 11:46:50.453241+07');
INSERT INTO public.transactions VALUES ('435ef550-5b4b-4803-aebf-4540b0eb4efe', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 12000, 'purchase', 'success', 'rfid', '2026-07-01 14:48:17.85654+07');
INSERT INTO public.transactions VALUES ('d682e474-fbfb-4ef9-b3f1-5e1003b2df1a', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 12000, 'purchase', 'success', 'rfid', '2026-07-02 09:48:54.49125+07');
INSERT INTO public.transactions VALUES ('4d6fa1ff-1874-4f74-a0ac-c00230a26172', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 12000, 'purchase', 'success', 'rfid', '2026-07-02 10:40:45.96988+07');
INSERT INTO public.transactions VALUES ('b12f28df-c45d-4cd6-aa48-1d8f13ff2216', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 24000, 'purchase', 'success', 'rfid', '2026-07-02 16:16:41.27638+07');
INSERT INTO public.transactions VALUES ('c2eeb855-ac6a-41a2-a6aa-433c5f542808', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '45ad99e3-5f4b-42ff-9f84-a85467cbe9b3', 100000, 'topup', 'success', 'rfid', '2026-07-03 09:49:31.078666+07');
INSERT INTO public.transactions VALUES ('5ab2fd99-7f84-4388-b53a-522d1623fc22', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 12000, 'purchase', 'success', 'rfid', '2026-07-03 09:49:53.197983+07');
INSERT INTO public.transactions VALUES ('13d0b1bb-bc1f-4af5-aacd-77aad82171c3', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 12000, 'purchase', 'cancelled', 'rfid', '2026-07-03 14:45:45.184588+07');
INSERT INTO public.transactions VALUES ('455ccf02-bace-4ab7-b8d4-07e25277bcef', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 12000, 'purchase', 'success', 'rfid', '2026-07-06 10:04:30.703476+07');
INSERT INTO public.transactions VALUES ('b0860249-5a01-4b28-97db-2a8243677e9f', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '45ad99e3-5f4b-42ff-9f84-a85467cbe9b3', 1000000000, 'topup', 'success', 'rfid', '2026-07-06 10:05:19.856877+07');
INSERT INTO public.transactions VALUES ('4460e3d8-01d4-4fa4-83bb-90771111cc2e', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '45ad99e3-5f4b-42ff-9f84-a85467cbe9b3', 1000000000, 'topup', 'success', 'rfid', '2026-07-06 10:05:45.251923+07');
INSERT INTO public.transactions VALUES ('e2553ed9-ff68-4d26-9879-d2b7bb9a649a', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 12000, 'purchase', 'cancelled', 'rfid', '2026-07-07 14:45:56.027844+07');
INSERT INTO public.transactions VALUES ('db1526b7-68db-4e76-9cf5-eca1aa593de6', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 12000, 'purchase', 'cancelled', 'rfid', '2026-07-07 14:51:40.064711+07');
INSERT INTO public.transactions VALUES ('d6fe73d7-7d66-4e26-8794-472a74dacdbf', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 1111, 'purchase', 'cancelled', 'rfid', '2026-07-07 16:33:07.790661+07');
INSERT INTO public.transactions VALUES ('3fbaca9a-b757-4a33-8df7-ddaea00a2e86', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 1111, 'purchase', 'cancelled', 'rfid', '2026-07-07 16:27:25.740198+07');
INSERT INTO public.transactions VALUES ('6ef66429-06f0-4f86-8e0f-eb117c60231d', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 1111, 'purchase', 'cancelled', 'rfid', '2026-07-07 15:29:25.131768+07');
INSERT INTO public.transactions VALUES ('69c8f1d5-6009-47b4-8d32-ad52c44e6ce9', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 12000, 'purchase', 'cancelled', 'rfid', '2026-07-07 15:12:20.723069+07');
INSERT INTO public.transactions VALUES ('0a82b974-b4f1-49d7-8389-54db100ee109', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 1111, 'purchase', 'cancelled', 'rfid', '2026-07-07 15:15:17.477258+07');
INSERT INTO public.transactions VALUES ('2d0ec55f-fb5e-4707-81ad-8989fddeef45', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 1111, 'purchase', 'cancelled', 'rfid', '2026-07-08 13:30:15.09517+07');
INSERT INTO public.transactions VALUES ('a1d28100-5fe0-4d4b-8608-6cdd0f5986fc', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 1111, 'purchase', 'cancelled', 'rfid', '2026-07-08 13:26:54.326418+07');
INSERT INTO public.transactions VALUES ('0e08ce1a-bcab-4bb1-a1e7-de7342c56797', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 1111, 'purchase', 'cancelled', 'rfid', '2026-07-08 11:59:23.949295+07');
INSERT INTO public.transactions VALUES ('cf0a539b-2a11-4f93-9209-8d334b67c00b', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 1111, 'purchase', 'cancelled', 'rfid', '2026-07-08 11:39:46.003131+07');
INSERT INTO public.transactions VALUES ('35efdafd-6d04-4dba-8995-d0fd4929933f', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 1111, 'purchase', 'cancelled', 'rfid', '2026-07-08 11:17:35.392654+07');
INSERT INTO public.transactions VALUES ('8297988e-933d-4b6a-b463-db0ad5f3f3ea', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 1111, 'purchase', 'cancelled', 'rfid', '2026-07-09 09:26:18.066069+07');
INSERT INTO public.transactions VALUES ('4c17a6e2-ebba-4872-861b-c215b06f4ae1', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 1111, 'purchase', 'cancelled', 'rfid', '2026-07-09 09:15:57.229263+07');
INSERT INTO public.transactions VALUES ('2cd397a6-a024-4a58-8938-6c4be7892504', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 1111, 'purchase', 'cancelled', 'rfid', '2026-07-09 09:14:20.286585+07');
INSERT INTO public.transactions VALUES ('964aef43-f1e4-4117-90be-0a0af971b1ff', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '45ad99e3-5f4b-42ff-9f84-a85467cbe9b3', 1000000000, 'topup', 'success', 'rfid', '2026-07-13 10:28:45.703667+07');
INSERT INTO public.transactions VALUES ('ba707f27-f026-46a7-9db1-711da7db9da3', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '45ad99e3-5f4b-42ff-9f84-a85467cbe9b3', 55000, 'topup', 'success', 'rfid', '2026-07-13 11:15:20.404172+07');
INSERT INTO public.transactions VALUES ('13e42591-1368-4f2f-a236-6fca3d7a6bb5', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '45ad99e3-5f4b-42ff-9f84-a85467cbe9b3', 50000, 'topup', 'success', 'rfid', '2026-07-13 11:16:13.44407+07');
INSERT INTO public.transactions VALUES ('39da234c-26d8-4163-a77b-453c9548947c', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '45ad99e3-5f4b-42ff-9f84-a85467cbe9b3', 20000, 'topup', 'success', 'rfid', '2026-07-15 09:28:10.267089+07');
INSERT INTO public.transactions VALUES ('b813dd1e-1a8e-4272-90b1-740e6a2b4868', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '45ad99e3-5f4b-42ff-9f84-a85467cbe9b3', 20000, 'topup', 'success', 'rfid', '2026-07-15 14:40:38.86484+07');
INSERT INTO public.transactions VALUES ('43f147df-07c0-4f53-8ae2-db73066fc57c', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '45ad99e3-5f4b-42ff-9f84-a85467cbe9b3', 20000, 'topup', 'success', 'rfid', '2026-07-21 09:51:49.512938+07');
INSERT INTO public.transactions VALUES ('83b030be-bdb0-4030-a10e-1bb45c60bd5b', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '45ad99e3-5f4b-42ff-9f84-a85467cbe9b3', 20000, 'topup', 'success', 'rfid', '2026-07-21 10:06:22.193094+07');
INSERT INTO public.transactions VALUES ('f876126c-bb0b-403e-a587-3a764faf6dd2', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '45ad99e3-5f4b-42ff-9f84-a85467cbe9b3', 100000, 'topup', 'success', 'rfid', '2026-07-21 11:01:01.386707+07');
INSERT INTO public.transactions VALUES ('e1978a69-a849-408f-80ea-77f3a986d7ca', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 111100, 'purchase', 'cancelled', 'rfid', '2026-07-29 10:22:51.371182+07');
INSERT INTO public.transactions VALUES ('783d1240-ee3e-4bb6-b86a-bb101dd9aba0', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 285000, 'purchase', 'success', 'rfid', '2026-07-29 10:25:09.456549+07');
INSERT INTO public.transactions VALUES ('677e0731-bc81-4d58-811c-9e8932fd141c', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '45ad99e3-5f4b-42ff-9f84-a85467cbe9b3', 500000, 'topup', 'success', 'rfid', '2026-07-29 10:29:55.699935+07');
INSERT INTO public.transactions VALUES ('5c4bc07e-2382-41b1-aa4c-6dba7f99af28', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 1111, 'purchase', 'pending', 'rfid', '2026-08-13 14:25:40.604606+07');
INSERT INTO public.transactions VALUES ('885ad17c-0f3c-4e46-aca2-a0bd483790ce', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 10231, 'purchase', 'pending', 'rfid', '2026-08-13 15:09:05.263681+07');
INSERT INTO public.transactions VALUES ('ecf926b2-1141-4f6c-a7ed-0d3d93b95ded', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 3111, 'purchase', 'pending', 'rfid', '2026-08-16 11:36:43.985246+07');
INSERT INTO public.transactions VALUES ('c00170a3-d14d-46ea-8e57-78d04ddc4088', 'e7925276-2188-4536-b146-73935cea8065', 'dbe4f12d-a2f2-45e0-94e8-8888bdf12345', 20000, 'topup', 'success', 'cash', '2026-08-20 16:02:52.167898+07');
INSERT INTO public.transactions VALUES ('21458e36-b3b0-4858-be20-376d7199776b', 'e7925276-2188-4536-b146-73935cea8065', '88888888-8888-8888-8888-888888888888', 20000, 'topup', 'success', 'cash', '2026-08-20 16:03:38.842323+07');
INSERT INTO public.transactions VALUES ('850922d7-8617-4219-a6a2-edb4b95fe39f', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'dbe4f12d-a2f2-45e0-94e8-8888bdf12345', 20000, 'topup', 'success', 'cash', '2026-08-20 16:09:12.489328+07');
INSERT INTO public.transactions VALUES ('e65b0493-94f6-4f1f-887a-a595ea804b5a', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '88888888-8888-8888-8888-888888888888', 20000, 'topup', 'success', 'cash', '2026-08-20 16:09:37.728794+07');
INSERT INTO public.transactions VALUES ('03cb49cd-8fb4-48ed-8afd-350de7dc5f13', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '88888888-8888-8888-8888-888888888888', 20000, 'topup', 'success', 'cash', '2026-08-20 16:09:44.111997+07');
INSERT INTO public.transactions VALUES ('994acde1-5cf3-4476-8e5e-537e8a4a482c', 'cd8c7092-f250-49c8-9a66-c4f1c76a2eea', '88888888-8888-8888-8888-888888888888', 20000, 'topup', 'success', 'cash', '2026-08-20 16:12:11.831549+07');
INSERT INTO public.transactions VALUES ('55524a41-861a-4b94-a9d8-d8cfbf49f905', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 5000, 'purchase', 'pending', 'app_order', '2026-08-20 16:17:32.140836+07');
INSERT INTO public.transactions VALUES ('de3046d6-1f65-4176-9e8b-56078c50f66b', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '98dd238b-b56c-4d27-8125-e0624385d2e7', 37000, 'purchase', 'pending', 'app_order', '2026-08-20 16:23:39.771356+07');
INSERT INTO public.transactions VALUES ('37a11123-4315-483e-807e-0dd737f5e889', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '98dd238b-b56c-4d27-8125-e0624385d2e7', 37000, 'purchase', 'pending', 'app_order', '2026-08-20 16:27:13.032939+07');
INSERT INTO public.transactions VALUES ('7d34837e-f127-4506-a311-f1e1214b542f', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '98dd238b-b56c-4d27-8125-e0624385d2e7', 7000, 'purchase', 'pending', 'app_order', '2026-08-20 16:28:29.319611+07');
INSERT INTO public.transactions VALUES ('966f0ab8-30e4-40c4-9100-3f83b74b2237', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'dbe4f12d-a2f2-45e0-94e8-8888bdf12345', 50000, 'topup', 'success', 'cash', '2026-08-20 16:41:36.243917+07');
INSERT INTO public.transactions VALUES ('5bcd09fe-bfdc-4d89-abf7-fb0065d8e64e', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '98dd238b-b56c-4d27-8125-e0624385d2e7', 7000, 'purchase', 'pending', 'app_order', '2026-08-20 16:50:51.208786+07');
INSERT INTO public.transactions VALUES ('b35c6298-e1ed-41d3-9e29-25417eb25954', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '98dd238b-b56c-4d27-8125-e0624385d2e7', 14000, 'purchase', 'pending', 'app_order', '2026-08-20 16:52:28.483044+07');
INSERT INTO public.transactions VALUES ('ce5246cc-38b2-41b5-bcde-a535873dd791', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '98dd238b-b56c-4d27-8125-e0624385d2e7', 14000, 'purchase', 'pending', 'app_order', '2026-08-20 16:52:53.36077+07');
INSERT INTO public.transactions VALUES ('0bc385c9-4495-4a1d-bf35-7fc3bdf99f30', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '98dd238b-b56c-4d27-8125-e0624385d2e7', 14000, 'purchase', 'pending', 'app_order', '2026-08-20 16:53:46.494606+07');
INSERT INTO public.transactions VALUES ('2908d25a-74f4-44ab-9411-83685b47981c', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '98dd238b-b56c-4d27-8125-e0624385d2e7', 3000, 'purchase', 'pending', 'app_order', '2026-08-20 16:53:54.525184+07');
INSERT INTO public.transactions VALUES ('53f8231d-fc4a-41a3-b811-12bcb2351396', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '98dd238b-b56c-4d27-8125-e0624385d2e7', 7000, 'purchase', 'pending', 'app_order', '2026-08-20 16:54:51.697016+07');
INSERT INTO public.transactions VALUES ('2cd30130-5227-4c17-aced-1dec7dc3f97a', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '98dd238b-b56c-4d27-8125-e0624385d2e7', 3000, 'purchase', 'pending', 'app_order', '2026-08-20 16:55:17.524647+07');
INSERT INTO public.transactions VALUES ('d45b4bf7-033f-449d-8576-5745a1fee10c', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '98dd238b-b56c-4d27-8125-e0624385d2e7', 3000, 'purchase', 'pending', 'app_order', '2026-08-20 16:55:33.309697+07');
INSERT INTO public.transactions VALUES ('811235c5-5563-4c71-9381-b966b5ec6b19', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '98dd238b-b56c-4d27-8125-e0624385d2e7', 7000, 'purchase', 'pending', 'app_order', '2026-08-20 16:56:11.544671+07');
INSERT INTO public.transactions VALUES ('a8e7da42-627b-4279-a627-17650ddc8c5a', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '98dd238b-b56c-4d27-8125-e0624385d2e7', 10, 'purchase', 'pending', 'app_order', '2026-08-20 16:56:57.845491+07');
INSERT INTO public.transactions VALUES ('e753c893-c63e-4f28-8caa-d65e99a86d08', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', 'dbe4f12d-a2f2-45e0-94e8-8888bdf12345', 100000, 'topup', 'success', 'cash', '2026-08-24 10:02:45.838666+07');
INSERT INTO public.transactions VALUES ('c8b5e4a8-b0c9-4509-9a57-6c815ef11cf6', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 30000, 'purchase', 'success', 'nfc_rfid', '2026-08-24 10:03:05.746384+07');
INSERT INTO public.transactions VALUES ('c410d42b-c34d-4130-9e47-0921fd0ba4c1', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 15000, 'purchase', 'success', 'nfc_rfid', '2026-08-24 10:28:07.173621+07');
INSERT INTO public.transactions VALUES ('ffc22e4b-3f3a-415d-ab82-b9c54144775c', '03525ad9-d9e3-4f55-8ee6-7ff5b06d2025', '6e5d9c21-1e80-4e92-86b9-1bb1e8ba258c', 30000, 'purchase', 'success', 'app_order', '2026-08-24 10:02:54.656864+07');


--
-- Data for Name: transaction_items; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.transaction_items VALUES ('b6403b12-8992-4faa-b4df-2411572db100', '45181373-e92e-4f0b-97a8-041528379a30', NULL, 1, 12000, '');
INSERT INTO public.transaction_items VALUES ('7e40fa54-bdb7-46fb-a2ef-dbff578ac184', '0a82b974-b4f1-49d7-8389-54db100ee109', NULL, 1, 1111, NULL);
INSERT INTO public.transaction_items VALUES ('ab56b4ea-eb4c-4884-ba7b-b92e1bd3b577', '6ef66429-06f0-4f86-8e0f-eb117c60231d', NULL, 1, 1111, NULL);
INSERT INTO public.transaction_items VALUES ('212c58fa-616d-4cb5-839e-9656682609fb', '3fbaca9a-b757-4a33-8df7-ddaea00a2e86', NULL, 1, 1111, NULL);
INSERT INTO public.transaction_items VALUES ('4c116408-282b-447b-be04-7d344288cac9', 'd6fe73d7-7d66-4e26-8794-472a74dacdbf', NULL, 1, 1111, NULL);
INSERT INTO public.transaction_items VALUES ('92c82000-3002-493f-bf4d-b82c6aefc61b', '35efdafd-6d04-4dba-8995-d0fd4929933f', NULL, 1, 1111, NULL);
INSERT INTO public.transaction_items VALUES ('02bfc560-8697-4fad-af8c-8a5bad3d034c', 'cf0a539b-2a11-4f93-9209-8d334b67c00b', NULL, 1, 1111, NULL);
INSERT INTO public.transaction_items VALUES ('cf0de81f-1c9d-435c-861f-539a011184fd', '0e08ce1a-bcab-4bb1-a1e7-de7342c56797', NULL, 1, 1111, NULL);
INSERT INTO public.transaction_items VALUES ('843dca54-6a99-4495-a116-54bacb26f283', 'a1d28100-5fe0-4d4b-8608-6cdd0f5986fc', NULL, 1, 1111, NULL);
INSERT INTO public.transaction_items VALUES ('8d861e47-68b6-4f6e-bdc6-c7e3cf687536', '2d0ec55f-fb5e-4707-81ad-8989fddeef45', NULL, 1, 1111, NULL);
INSERT INTO public.transaction_items VALUES ('39e83184-6bea-4178-abff-6338a85a4180', '2cd397a6-a024-4a58-8938-6c4be7892504', NULL, 1, 1111, NULL);
INSERT INTO public.transaction_items VALUES ('269643b3-85af-4eee-8a78-723cf8afae2c', '4c17a6e2-ebba-4872-861b-c215b06f4ae1', NULL, 1, 1111, NULL);
INSERT INTO public.transaction_items VALUES ('87084e9d-d4ec-4d05-b79f-e67eea9a87e0', '8297988e-933d-4b6a-b463-db0ad5f3f3ea', NULL, 1, 1111, NULL);
INSERT INTO public.transaction_items VALUES ('2af7a1d9-2215-484b-a300-2983e66a548e', 'e1978a69-a849-408f-80ea-77f3a986d7ca', NULL, 100, 1111, NULL);
INSERT INTO public.transaction_items VALUES ('6bad6f59-684d-4040-88e0-f809c308d3e5', '5c4bc07e-2382-41b1-aa4c-6dba7f99af28', NULL, 1, 1111, NULL);
INSERT INTO public.transaction_items VALUES ('86e29012-ef64-489a-950d-a041e85bf1f8', 'ecf926b2-1141-4f6c-a7ed-0d3d93b95ded', NULL, 1, 1111, NULL);
INSERT INTO public.transaction_items VALUES ('82112fe4-36a7-4029-9364-e96d59372e1f', '885ad17c-0f3c-4e46-aca2-a0bd483790ce', NULL, 1, 10231, NULL);
INSERT INTO public.transaction_items VALUES ('b93a68d7-c26d-4fbe-8a7f-b4c2dd63230f', '45181373-e92e-4f0b-97a8-041528379a30', NULL, 1, 4000, '');
INSERT INTO public.transaction_items VALUES ('b6d814ee-5ba1-4195-9b87-787163d60649', '45181373-e92e-4f0b-97a8-041528379a30', NULL, 1, 2500, '');
INSERT INTO public.transaction_items VALUES ('ca0949cc-451d-450d-a0a4-93cd1305ec07', 'c8b5e4a8-b0c9-4509-9a57-6c815ef11cf6', NULL, 2, 15000, NULL);
INSERT INTO public.transaction_items VALUES ('0fff9121-79c6-4dc9-9291-73ccf0429ccb', 'c410d42b-c34d-4130-9e47-0921fd0ba4c1', NULL, 1, 15000, '');
INSERT INTO public.transaction_items VALUES ('0651b697-3c8b-440e-9fbf-7bc682d43808', '80a92961-f006-4cbc-85c4-acf1438ee283', NULL, 1, 12000, NULL);
INSERT INTO public.transaction_items VALUES ('545faa21-0649-47cb-8acf-478e153df59f', '80a92961-f006-4cbc-85c4-acf1438ee283', NULL, 1, 12000, NULL);
INSERT INTO public.transaction_items VALUES ('c64966ca-0cc6-45bd-8853-b5aa3f867d16', '34cfd397-23a9-4491-b7cc-b191bbb241d4', NULL, 1, 12000, NULL);
INSERT INTO public.transaction_items VALUES ('adb9f27e-faf0-4cf6-b050-8c8f72dce2d1', '435ef550-5b4b-4803-aebf-4540b0eb4efe', NULL, 1, 12000, NULL);
INSERT INTO public.transaction_items VALUES ('15416483-02d0-4680-93c7-4734e9dac2de', 'd682e474-fbfb-4ef9-b3f1-5e1003b2df1a', NULL, 1, 12000, NULL);
INSERT INTO public.transaction_items VALUES ('7dc98fd4-11e3-430f-97b1-cebd1c26b981', '4d6fa1ff-1874-4f74-a0ac-c00230a26172', NULL, 1, 12000, NULL);
INSERT INTO public.transaction_items VALUES ('d0fccdec-71a7-44dc-9cd8-117a5697e363', 'b12f28df-c45d-4cd6-aa48-1d8f13ff2216', NULL, 1, 12000, NULL);
INSERT INTO public.transaction_items VALUES ('9536d263-0d41-4337-8ee1-d5527b8eaf1b', 'b12f28df-c45d-4cd6-aa48-1d8f13ff2216', NULL, 1, 12000, NULL);
INSERT INTO public.transaction_items VALUES ('3eaff8ae-3f51-4530-bdc9-908080203030', '5ab2fd99-7f84-4388-b53a-522d1623fc22', NULL, 1, 12000, NULL);
INSERT INTO public.transaction_items VALUES ('7c920df4-5078-40fc-b119-ea3fd33aa715', '13d0b1bb-bc1f-4af5-aacd-77aad82171c3', NULL, 1, 12000, NULL);
INSERT INTO public.transaction_items VALUES ('12792a14-97fb-4dc8-8e3e-839459b8e8ed', '455ccf02-bace-4ab7-b8d4-07e25277bcef', NULL, 1, 12000, NULL);
INSERT INTO public.transaction_items VALUES ('da4c9fb9-69be-433c-9988-44c3b7597325', 'e2553ed9-ff68-4d26-9879-d2b7bb9a649a', NULL, 1, 12000, NULL);
INSERT INTO public.transaction_items VALUES ('03a13a1d-aaa2-47bb-a5db-ccad4f88f589', 'db1526b7-68db-4e76-9cf5-eca1aa593de6', NULL, 1, 12000, NULL);
INSERT INTO public.transaction_items VALUES ('ae52fc82-f5d1-4774-a997-326447f9d340', '69c8f1d5-6009-47b4-8d32-ad52c44e6ce9', NULL, 1, 12000, NULL);
INSERT INTO public.transaction_items VALUES ('471ce6a7-3a93-4777-a3aa-7a7b9d734305', '783d1240-ee3e-4bb6-b86a-bb101dd9aba0', NULL, 15, 19000, NULL);


--
-- Data for Name: user_sessions; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- PostgreSQL database dump complete
--

\unrestrict 71S0OPXuxl9tCU5Q9QkZmdmi9RVlkmaBAiGd4NGGmiRW5sEpyNsHFqI8jV7f1cw

