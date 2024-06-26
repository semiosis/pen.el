(require 'abbrev)
(require 'pen-japanese)

;; https://youtu.be/ruPpRlh2re4?t=110


;; https://learnjapanesedaily.com/most-common-japanese-words.html
(defset japanese-words
        "
Day 1
1. 行く (iku) : go
2. 見る (miru) : see, look at
3. 多い (ooi) : a lot of, many
4. 家 (ie) : home, household
5. これ (kore) : this, this one
6. それ (sore) : that, that one
7. 私 (watashi) : I
8. 仕事 (shigoto) : work, job
9. いつ (itsu) : when
10. する (suru) : do, make
Day 2
11. 出る (deru) : go out, leave
12. 使う (tsukau) : use, make use of
13. 所 (tokoro) : place
14. 作る (tsukuru) : make, create
15. 思う (omou) : think
16. 持つ (motsu) : have, possess
17. 買う (kau) : buy
18. 時間 (jikan) : time, hour
19. 知る (shiru) : know
20. 同じ (onaji) : same, identical
Day 3
21. 今 (ima) : now
22. 新しい (atarashii) : new
23. なる (naru) : become
24. まだ (mada) : (not) yet, still
25. あと (ato) : after
26. 聞く (kiku) : hear, ask
27. 言う (iu) : say, tell
28. 少ない (sukunai) : few, little
29. 高い (takai) : high, tall
30. 子供 (kodomo) : child
Day 4
31. そう (sou) : so, that way
32. もう (mou) : already, yet
33. 学生 (gakusei) : student
34. 熱い (atsui) : hot (to touch)
35. どうぞ (douzo) : please
36. 午後 (gogo) : afternoon, p.m.
37. 長い (nagai) : long
38. 本 (hon) : book, volume
39. 今年 (kotoshi) : this year (colloquial)
40. よく (yoku) : often, well
Day 5
41. 彼女 (kanojo) : she, one’s girlfriend
42. どう (dou) : how, what
43. 言葉 (kotoba) : word, language
44. 顔 (kao) : face
45. 終わる (owaru) : finish, end
46. 一つ (hitotsu) : one (thing)
47. あげる (ageru) : give, offer (colloquial)
48. こう (kou) : like this, such
49. 学校 (gakkou) : school
50. くれる (kureru) : be given
Day 6
51. 始める (hajimeru) : start (something)
52. 起きる (okiru) : get up, get out of bed
53. 春 (haru) : spring
54. 午前 (gozen) : morning, a.m.
55. 別 (betsu) : another, different
56. どこ (doko) : where
57. 部屋 (heya) : room
58. 若い (wakai) : young
59. 車 (kuruma) : car, automobile
60. 置く (oku) : put, place
Day 7
61. 住む (sumu) : live, reside
62. 働く (hataraku) : work
63. 難しい (muzukashii) : difficult
64. 先生 (sensei) : teacher
65. 立つ (tatsu) : stand, rise
66. 呼ぶ (yobu) : call, name
67. 大学 (daigaku) : university, college
68. 安い (yasui) : cheap, inexpensive
69. もっと (motto) : more
70. 帰る (kaeru) : go back home
Day 8
71. 分かる (wakaru) : understand
72. 広い (hiroi) : wide, big
73. 数 (suu) : number
74. 近い (chikai) : near, close
75. そこ (soko) : there
76. 走る (hashiru) : run
77. 入れる (ireru) : put in
78. 教える (oshieru) : teach, tell
79. 歩く (aruku) : walk, go on foot
80. 会う (au) : meet
Day 9
81. 書く (kaku) : write
82. 頭 (atama) : head
83. 売る (uru) : sell
84. 大好き (daisuki) : like (something) a lot
85. 体 (karada) : body, physique
86. 直ぐ (sugu) : at once, soon
87. 飛ぶ (tobu) : fly
88. とても (totemo) : very (colloquial)
89. 誰 (dare) : who
90. 好き (suki) : favorite, liked
Day 10
91. 読む (yomu) : read
92. 次 (tsugi) : next
93. あなた (anata) : you
94. 飲む (nomu) : drink
95. 古い (furui) : old
96. 質問 (shitsumon) : question
97. 今日 (kyou) : today (colloquial)
98. 友達 (tomodachi) : friend, companion (colloquial)
99. 早い (hayai) : early
100. どれ (dore) : what, which
Day 11
101. 美しい (utsukushii) : beautiful
102. いつも (itsumo) : always (colloquial)
103. 足 (ashi) : leg, foot
104. 起こす (okosu) : wake (someone) up
105. 見せる (miseru) : show
106. 娘 (musume) : daughter, girl
107. 楽しむ (tanoshimu) : enjoy
108. 色 (iro) : color
109. みんな (minna) : everybody (colloquial)
110. 取る (toru) : take, get
Day 12
111. 勉強 (benkyou) : study
112. できる (dekiru) : can do, be good at
113. 短い (mijikai) : short, brief
114. 落ちる (ochiru) : fall, come down
115. 息子 (musuko) : son
116. 白い (shiroi) : white, blank
117. 飛行機 (hikouki) : airplane
118. 病気 (byouki) : illness
119. 冬 (fuyu) : winter
120. 年 (toshi) : year, age
Day 13
121. 重い (omoi) : heavy
122. 胸 (mune) : chest, breast
123. 払う (harau) : pay (money, respect, attention, etc.)
124. 軽い (karui) : light (of weight)
125. 見つける (mitsukeru) : find
126. 忘れる (wasureru) : forget, leave behind
127. 酒 (sake) : alcohol, rice wine
128. どちら (dochira) : which (polite)
129. 姉 (ane) : (one’s own) older sister
130. 覚える (oboeru) : memorize, learn
Day 14
131. 狭い (semai) : narrow, small
132. 赤い (akai) : red
133. 着る (kiru) : wear, put on
134. 笑う (warau) : laugh, smile
135. 一番 (ichiban) : most, best
136. 授業 (jugyou) : class session, lecture
137. 週 (shuu) : week
138. 漢字 (kanji) : Chinese character
139. 自転車 (jitensha) : bicycle
140. 電車 (densha) : train
Day 15
141. 探す (sagasu) : search for, look for
142. 紙 (kami) : paper
143. 歌う (utau) : sing
144. 遅い (osoi) : slow, late
145. 首 (kubi) : neck
146. 速い (hayai) : fast
147. 一緒に (issho ni) : together, at the same time
148. 今月 (kongetsu) : this month
149. 遊ぶ (asobu) : play
150. 遠い (tooi) : far, distant
Day 16
151. 弱い (yowai) : weak
152. 耳 (mimi) : ear
153. 座る (suwaru) : sit, sit down
154. 右 (migi) : right
155. 浴びる (abiru) : take (a shower)
156. 肩 (kata) : shoulder
157. 寝る (neru) : lie down and sleep, go to sleep
158. 消す (kesu) : switch off, turn off
159. 元気 (genki) : healthy, energetic
160. 全部 (zenbu) : all, whole
Day 17
161. 去年 (kyonen) : last year (colloquial)
162. 引く (hiku) : draw, pull
163. 図書館 (toshokan) : library
164. 上げる (ageru) : raise, lift
165. 緑 (midori) : green
166. 腕 (ude) : arm
167. ドア (doa) : door (loan word)
168. 女の子 (onna no ko) : little girl
169. 男の子 (otoko no ko) : boy
170. 私たち (watashitachi) : we (colloquial)
Day 18
171. 近く (chikaku) : near, close to
172. やる (yaru) : do, give
173. かなり (kanari) : fairly, rather
174. 国 (kuni) : country
175. 起こる (okoru) : happen
176. 秋 (aki) : autumn, fall
177. 送る (okuru) : send
178. 死ぬ (shinu) : die
179. 気持ち (kimochi) : feeling, sensation
180. 乗る (noru) : ride, take
Day 19
181. いる (iru) : be present, stay
182. 木 (ki) : tree, wood
183. 開ける (akeru) : open, unlock (doors, windows, etc.)
184. 閉める (shimeru) : shut, close (doors, windows, etc.)
185. 続く (tsuzuku) : continue, follow
186. お医者さん (oishasan) : doctor (polite)
187. 円 (en) : Japanese yen
188. ここ (koko) : here
189. 待つ (matsu) : wait, wait for
190. 低い (hikui) : low, short
Day 20
191. もらう (morau) : receive
192. 食べる (taberu) : eat
193. 兄 (ani) : (one’s own) older brother
194. 名前 (namae) : name
195. 夫 (otto) : husband
196. 一 (ichi) : one
197. 結婚 (kekkon) : marriage
198. 親 (oya) : parent
199. 話す (hanasu) : speak, talk
200. 少し (sukoshi) : a bit, a little while
Day 21
201. 閉じる (tojiru) : shut, close (books, eyes, etc.)
202. 時 (toki) : time, moment
203. 米 (kome) : rice (grain)
204. 切る (kiru) : cut
205. 楽しい (tanoshii) : fun, enjoyable
206. 服 (fuku) : clothes (colloquial)
207. 後ろ (ushiro) : back, behind
208. 嬉しい (ureshii) : happy, glad
209. 腰 (koshi) : waist, lower back
210. 日曜日 (nichiyoubi) : Sunday
Day 22
211. 昼 (hiru) : daytime, midday
212. お母さん (okaasan) : mother (colloquial)
213. 大学生 (daigakusei) : university student
214. 終わり (owari) : end, conclusion
215. 背 (se) : height, stature
216. 手伝う (tetsudau) : help, assist
217. 鼻 (hana) : nose
218. 起きる (okiru) : occur, happen, wake up, get up
219. 載せる (noseru) : place, put on
220. 悲しい (kanashii) : sad
Day 23
221. しゃべる (shaberu) : chat, talk
222. 近く (chikaku) : in the near future, before long
223. 甘い (amai) : sweet
224. テーブル (te-buru) : table
225. 食べ物 (tabemono) : food (colloquial)
226. 始まる (hajimaru) : begin
227. ゲーム (ge-mu) : game
228. 十 (juu) : ten
229. 天気 (tenki) : weather
230. 暑い (atsui) : hot (of weather)
Day 24
231. 太い (futoi) : thick, fat
232. 晩 (ban) : evening, night (from sunset to bedtime)
233. 土曜日 (doyoubi) : Saturday
234. 痛い (itai) : sore, painful
235. お父さん (otousan) : father, dad (colloquial)
236. 多分 (tabun) : probably, perhaps
237. 時計 (tokei) : clock, watch
238. 泊まる (tomaru) : stay overnight
239. どうして (doushite) : how come
240. 掛ける (kakeru) : hang, put on
Day 25
241. 曲がる (magaru) : make a turn, turn
242. お腹 (onaka) : stomach, belly
243. ミーティング (mi-tingu) : meeting
244. 嫌い (kirai) : dislike (habitual)
245. 金曜日 (kinyoubi) : Friday
246. 要る (iru) : need, require
247. 無い (nai) : to not be
248. 風邪 (kaze) : cold (illness)
249. 黄色い (kiiroi) : yellow
250. 優しい (yasashii) : gentle, kind
Day 26
251. 晴れる (hareru) : be sunny, clear up
252. 汚い (kitanai) : dirty
253. 茶色 (chairo) : brown
254. 空く (suku) : be empty, become less crowded
255. 上る (noboru) : go up, climb
256. ご飯 (gohan) : meal, cooked rice
257. 日 (nichi) : counter for days
258. 髪の毛 (kaminoke) : hair, each single hair
259. つける (tsukeru) : switch on, turn on
260. 月曜日 (getsuyoubi) : Monday
Day 27
261. 入る (hairu) : enter
262. カタカナ (katakana) : katakana
263. 今週 (konshuu) : this week
264. 開く (hiraku) : open (books, eyes, etc.)
265. 水 (mizu) : water
266. あれ (are) : that (over there)
267. 二 (ni) : two
268. 締める (shimeru) : tighten, fasten
269. まずい (mazui) : bad (taste), distasteful
270. 平仮名 (hiragana) : hiragana
Day 28
271. 曇る (kumoru) : become cloudy
272. 触る (sawaru) : touch, feel
273. 駄目 (dame) : no good
274. 飲み物 (nomimono) : beverage, drink
275. 木曜日 (mokuyoubi) : Thursday
276. 曜日 (youbi) : day of the week
277. そば (soba) : side, vicinity
278. こっち (kocchi) : here, this way (casual)
279. 火曜日 (kayoubi) : Tuesday
280. 渇く (kawaku) : be thirsty
Day 29
281. 三 (san) : three
282. 水曜日 (suiyoubi) : Wednesday
283. 二つ (futatsu) : two (things)
284. 今晩 (konban) : this evening, tonight
285. 千 (sen) : thousand
286. 六日 (muika) : six days, sixth of the month
287. お姉さん (onesan) : older sister
288. 直る (naoru) : be repaired, get fixed
289. ちょっと (chotto) : just a moment, just a little
290. 四 (yon) : four (Japanese origin)
Day 30
291. これから (korekara) : from now on, after this
292. 考える (kangaeru) : think, consider
293. 戻る (modoru) : return to a point of departure
294. 変える (kaeru) : change (something), alter
295. 朝 (asa) : morning
296. 歯 (ha) : tooth
297. 頑張る (ganbaru) : work hard, do one’s best
298. 携帯電話 (keitaidenwa) : cellular phone
299. 雨 (ame) : rain
300. 金 (kane) : money (colloquial)
Day 31
301. 易しい (yasashii) : easy, simple (colloquial)
302. お兄さん (oniisan) : older brother
303. 大きい (ooki) : big
304. 小さい (chiisai) : small
305. 辛い (karai) : spicy, hot
306. 八 (hachi) : eight
307. あそこ (asoko) : over there
308. 来る (kuru) : come
309. 前 (mae) : front, before
310. 五日 (itsuka) : five days, fifth of the month
Day 32
311. いっぱい (ippai) : full
312. 九 (kyu) : nine (used before counter words
and in decimal places)
313. 酸っぱい (suppai) : sour
314. 違う (chigau) : differ, be wrong
315. 細い (hosoi) : thin, slender
316. 三つ (mittsu) : three (things)
317. 八日 (youka) : eight days, eighth of the month
318. 高校生 (koukousei) : high school student
319. 上手 (jouzu) : good, skilled
320. 強い (tsuyoi) : strong
Day 33
321. 七 (nana) : seven (Japanese origin)
322. 二十日 (hatsuka) : 20 days, 20th of the month
323. 左 (hidari) : left
324. 二日 (futsuka) : two days, second of the month
325. 四つ (yottsu) : four (things)
326. 暖かい (atatakai) : warm
327. ある (aru) : exist, there is
328. いい (ii) : good (informal/spoken form)
329. 上 (ue) : up, above
330. 駅 (eki) : train station
Day 34
331. 美味しい (oishii) : tasty
332. 昨日 (kinou) : yesterday (colloquial)
333. 綺麗 (kirei) : pretty, clean
334. 五 (go) : five
335. 九つ (kokonotsu) : nine (things)
336. お願い (onegai) : favor
337. 答える (kotaeru) : give an answer
338. 先 (saki) : ahead, first
339. 寒い (samui) : cold (temperature of the air)
340. 四 (shi) : four (Chinese origin)
Day 35
341. 三日 (mikka) : three days, third of the month
342. 下 (shita) : under, below
343. 大丈夫 (daijoubu) : all right, OK
344. 大人 (otona) : adult
345. 出す (dasu) : take out
346. 父 (chichi) : (speaker’s) father
347. 母 (haha) : (speaker’s) mother
348. 月 (tsuki) : moon
349. 妹 (imouto) : younger sister
350. 冷たい (tsumetai) : cold (to touch)
Day 36
351. 弟 (otouto) : younger brother
352. 手 (te) : hand
353. 十日 (tooka) : ten days, tenth of the month
354. 口 (kuchi) : mouth
355. 夏 (natsu) : summer
356. 七つ (nanatsu) : seven (things)
357. 時々 (tokidoki) : sometimes
358. 何 (nani) : what
359. 人 (hito) : person
360. 一人 (hitori) : one person
Day 37
361. 一日 (tsuitachi) : first of the month
362. 九日 (kokonoka) : nine days, ninth of the month
363. 方 (hou) : direction, side
364. 他 (hoka) : other (Japanese origin)
365. 僕 (boku) : I, me (usually used by young males)
366. 欲しい (hoshii) : want, desire (of the speaker)
367. 万 (man) : ten thousand
368. 見える (mieru) : be visible, can see
369. 道 (michi) : street, way
370. 五つ (itsutsu) : five (things)
Day 38
371. 目 (me) : eye
372. 八つ (yattsu) : eight (things)
373. 止める (tomeru) : stop (a car…). 止める (yameru) give up
374. 四日 (yokka) : four days, fourth of the month
375. 夜 (yoru) : night (from sunset to sunrise)
376. 来年 (rainen) : next year
377. 六 (roku) : six
378. 悪い (warui) : bad
379. お手洗い (otearai) : toilet, bathroom
380. ご主人 (goshujin) : (someone else’s) husband
Day 39
381. 本当に (hontouni) : really, truly
382. 自分 (jibun) : self, oneself
383. ため (tame) : sake, purpose
384. 見つかる (mitsukaru) : be found, be caught
385. 休む (yasumu) : take a rest, take a break
386. ゆっくり (yukkuri) : slowly
387. 六つ (muttsu) : six (things)
388. 花 (hana) : flower
389. 動く (ugoku) : move
390. 線 (sen) : line
Day 40
391. 七日 (nanoka) : seven days, seventh of the month
392. 以外 (igai) : except for
393. 男 (otoko) : man, male
394. 彼 (kare) : he, one’s boyfriend
395. 女 (onna) : woman
396. 妻 (tsuma) : woman
397. 百 (hyaku) : hundred
398. 辺 (atari) : vicinity
399. 店 (mise) : shop, store
400. 閉まる (shimaru) : be shut, be closed
Day 41
401. 問題 (mondai) : problem, question
402. 必要 (hitsuyou) : need, necessary
403. もつ (motsu) : last long, be durable
404. 開く (hiraku) : open
405. 昨年 (sakunen) : last year (formal, often used in writing)
406. 治る (naoru) : be cured, get well
407. ドル (doru) : dollar
408. システム (shisutemu) : system (loan word)
409. 以上 (ijou) : more than, not less than
410. 最近 (saikin) : recent, latest
Day 42
411. 世界 (sekai) : world
412. コンピューター (konpyu-ta-) : computer
413. やる (yaru) : give (to an inferior)
414. 意味 (imi) : meaning, sense
415. 増える (fueru) : increase, accrue
416. 選ぶ (erabu) : choose, elect
417. 生活 (seikatsu) : life, living
418. 進める (susumeru) : go ahead, proceed
419. 続ける (tsuzukeru) : continue, keep up
420. ほとんど (hotondo) : almost, hardly
Day 43
421. 会社 (kaisha) : company, corporation
422. 家 (ie) : house, dwelling
423. 多く (ooku) : much, largely
424. 話 (hanashi) : talk, story
425. 上がる (agaru) : go up, rise (physical movement)
426. もう (mou) : another, again
427. 集める (atsumeru) : collect, gather
428. 声 (koe) : voice, sound
429. 初めて (hajimete ) : for the first time
430. 変わる (kawaru) : change, turn into
Day 44
431. まず (mazu) : first of all, to begin with
432. 社会 (shakai) : society
433. プログラム (puroguramu) : program booklet
434. 力 (chikara) : strength, power
435. 今回 (konkai) : this time
436. 予定 (yotei) : schedule, plan
437. まま (mama) : as is, still (in the current state)
438. テレビ (terebi) : television
439. 減る (heru) : decrease, diminish
440. 消える (kieru) : be extinguished, disappear
Day 45
441. 家族 (kazoku) : family, household
442. 比べる (kuraberu) : compare, contrast
443. 生まれる (umareru) : be born, come into existence
444. ただ (tada) : free
445. これら (korera) : these
446. 調べる (shiraberu) : investigate, check
447. 事故 (jiko) : accident, trouble
448. 電話 (denwa) : telephone, phone call
449. 外国 (gaikoku) : foreign country
450. 銀行 (ginkou) : bank
Day 46
451. 十分 (juubun) : enough, plentiful
452. あまり (amari) : (not) much
453. 写真 (shashin) : photograph
454. 繰り返す (kurikaesu) : repeat
455. 種類 (shurui) : kind, type
456. 意見 (iken) : opinion
457. 新聞 (shinbun) : newspaper
458. 文章 (bunshou) : sentence, writing
459. 目立つ (medatsu) : stand out, be conspicuous
460. 相手 (aite) : opponent, the other party
Day 47
461. 病院 (byouin) : hospital
462. 厚い (atsui) : thick, bulky
463. 忙しい (isogashii) : busy, occupied
464. 薄い (usui) : thin, weak
465. 川 (kawa) : river, stream
466. 暗い (kurai) : dark, gloomy
467. クラス (kurasu) : class (in school)
468. 黒い (kuroi) : black, dark
469. バス (basu) : bus
470. 青い (aoi) : blue
Day 48
471. 買い物 (kaimono) : shopping, purchase
472. 薬 (kusuri) : drug, medicine
473. 砂糖 (satou) : sugar
474. 休み (yasumi) : holiday, break
475. 郵便局 (yuubinkyoku) : post office
476. 住所 (juusho) : address
477. こちら (kochira) : here, this way (polite)
478. 財布 (saifu) : purse, wallet
479. パスポート (pasupo-to) : passport
480. 椅子 (isu) : chair
Day 49
481. 可愛い (kawaii) : cute, sweet
482. お祖父さん (ojiisan) : grandfather (colloquial)
483. 切手 (kitte) : postage stamp
484. 涼しい (suzushii) : cool (of temperature)
485. いくつ (ikutsu) : how many, how old
486. メニュー (menyu-) : menu
487. 電気 (denki) : electricity, electric light
488. 勝つ (katsu) : win
489. 負ける (makeru) : lose
490. 建てる (tateru) : build, erect
Day 50
491. 日記 (nikki) : diary
492. 売り切れ (urikire) : sell out
493. お巡りさん (omawarisan) : police officer (colloquial)
494. 目覚まし時計 (mezamashitokei) : alarm clock
495. レシート (reshi-to) : receipt (loan word)
496. ティッシュ (tisshu) : tissue
497. 歯ブラシ (haburashi) : toothbrush
498. 下りる (oriru) : go down, come down
499. 洗う (arau) : wash
500. パート (pa-to) : part-time
Day 51
501. 氏名 (shimei) : full name
502. 今夜 (konya) : tonight, this evening
503. 夜中 (yonaka) : midnight
504. 来週 (raishuu) : next week
505. 誰か (dareka) : someone
506. 何 (nan) : what. それはなんですか. What is that?
507. 今朝 (kesa) : this morning
508. 寿司 (sushi) : sushi
509. 履く (haku) : put on (shoes), wear (pants, skirt)
510. おじさん (ojisan) : uncle
Day 52
511. おばさん (obasan) : aunt
512. お祖母さん (obaasan) : grandmother (colloquial)
513. いとこ (itoko) : cousin
514. 辞書 (jisho) : dictionary (category)
515. 朝ご飯 (asagohan) : breakfast
516. 白 (shiro) : white
517. どっち (docchi) : which (casual)
518. そっち (socchi) : there (casual)
519. 明日 (ashita) : tomorrow (colloquial)
520. 明後日 (myougonichi/asatte) : day after tomorrow (colloquial)
Day 53
521. 一昨日 (ototoi) : the day before yesterday (colloquial)
522. 庭 (niwa) : garden, yard
523. 左側 (hidarigawa) : left side
524. 右側 (migigawa) : right side
525. 指 (yubi) : finger, toe
526. 眼鏡 (megane) : glasses
527. 鞄 (kaban) : bag, handbag
528. あっち (acchi) : other side, over there (casual)
529. 大人しい (otonashii) : gentle, quiet
530. 下手 (heta) : not good at
Day 54
531. 厳しい (kibishii) : strict, severe
532. 一人で (hitoride) : by oneself, alone
533. 答え (kotae) : answer, solution
534. この頃 (konogoro) : these days, recently
535. 残念 (zannen) : regretful, disappointing
536. 仕舞う (shimau) : put away, put in
537. 心配 (shinpai) : anxiety, worry
538. 外 (soto) : outside, open air
539. 大切 (taisetsu) : important, valuable
540. ちょうど (choudo) : just, exactly
Day 55
541. 助ける (tasukeru) : help, save
542. 勤める (tsutomeru) : serve, hold a job
543. 連れていく (tsureteiku) : take along, bring along (a person)
544. 丈夫 (joubu) : healthy, sturdy
545. 賑やか (nigiyaka) : lively, exciting
546. 眠い (nemui) : sleepy
547. 山 (yama) : mountain
548. 橋 (hashi) : bridge
549. 止まる (tomaru) : come to a stop, cease
550. 降る (furu) : fall, come down (rain, snow, etc.)
Day 56
551. 本当 (hontou) : reality, genuine
552. 町 (machi) : town, city
553. お菓子 (okashi) : sweets, snacks
554. 緩い (yurui) : slack, loose
555. 良い (yoi) : good (formal/written form)
556. ようこそ (youkoso) : welcome (greeting)
557. お土産 (omiyage) : souvenir (polite)
558. 両親 (ryoushin) : parents
559. ウェーター (we-ta-) : waiter
560. ウェートレス (we-toresu) : waitress
Day 57
561. 絶対に (zettaini) : absolutely, definitely
562. ごちそう (gochisou) : feast, treat
563. フォーク (fo-ku) : fork
564. スプーン (supu-n) : spoon
565. 瓶 (bin) : bottle
566. つく (tsuku) : be on, be switched on
567. 醤油 (shouyu) : soy sauce
568. 茶碗 (chawan) : rice bowl
569. 決める (kimeru) : decide, agree upon
570. 感じる (kanjiru) : feel, sense
Day 58
571. 生きる (ikiru) : live (one’s life)
572. 動かす (ugokasu) : move (something)
573. 壊れる (kowareru) : break, break down
574. 復習 (fukushuu) : review
575. 眉 (mayu) : eyebrow
576. 客 (kyaku) : visitor, customer
577. 机 (tsukue) : desk
578. 風呂 (furo) : bath
579. 湯 (yu) : hot water
580. ぬるい (nurui) : tepid, lukewarm
Day 59
581. 風邪薬 (kazegusuri) : cold medicine
582. 靴下 (kutsushita) : socks
583. タバコ (tabako) : tobacco, cigarette
584. アイスコーヒー (aisuko-hi-) : iced coffee
585. 天ぷら (tempura) : Japanese deep-fried food
586. 肉 (niku) : flesh, meat
587. 昨夜 (sakuya) : last night, last evening (colloquial)
588. 流行る (hayaru) : be in fashion, be popular
589. 連れて来る (tsuretekuru) : bring (a person)
590. 方 (kata) : person (polite form)
Day 60
591. 零 (rei) : zero
592. 雲 (kumo) : cloud
593. 空 (sora) : sky
594. 人気 (ninki) : popularity
595. 兄さん (niisan) : (one’s own) older brother (polite)
596. 姉さん (neesan) : (one’s own) older sister (polite)
597. 平成 (heisei) : Heisei era
598. 毎月 (maitsuki) : every month
599. 半日 (hannichi) : half a day
600. 半月 (hantsuki) : half a month
Day 61
601. なるほど (naruhodo) : I see, really
602. つまり (tsumari) : in short, that is to say
603. そのまま (sonomama) : as it is, just like that
604. はっきり (hakkiri) : clearly
605. 大変 (taihen) : awful, hard
606. 簡単 (kantan) : simple, easy
607. 似ている (niteiru) : look like, resemble
608. 驚く (odoroku) : be surprised, be startled
609. 嫌 (iya/ kira-i) : dislike (situational)
610. 喧嘩 (kenka) : fight, argument
Day 62
611. 遅れる (okureru) : be late
612. にんじん (ninjin) : carrot
613. ジャガイモ (jagaimo) : potato
614. ナス (nasu) : eggplant
615. やかん (yakan) : kettle
616. 話し合う (hanashiau) : discuss, talk over
617. 残す (nokosu) : leave, leave undone
618. ごちそうする (gochisousuru) : treat, host (a meal)
619. 合う (au) : fit, match
620. 当たる (ataru) : (go straight and) hit, strike
Day 63
621. 集まる (atsumaru) : gather, be collected
622. 場所 (basho) : place, space
623. 海 (umi) : sea, ocean
624. 少年 (shounen) : boy (between 7 and 18 years old)
625. 孫 (mago) : grandchild
626. 生徒 (seito) : pupil, student
627. 高校 (koukou) : high school (for short)
628. 年上 (toshiue) : older, senior
629. 卒業 (sotsugyou) : graduation
630. 運動 (undou) : movement, exercise
Day 64
631. 選手 (senshu) : athlete, (sports) player
632. 映画 (eiga) : movie
633. 英語 (eigo) : English
634. 手紙 (tegami) : letter
635. 動物 (doubutsu) : animal
636. 音 (oto) : sound, noise
637. 海外 (kaigai) : overseas, abroad
638. 外国人 (gaikokujin) : foreigner
639. 帰国 (kikoku) : return to one’s country
640. 彼ら (karera) : they
Day 65
641. 機械 (kikai) : machine
642. 基本 (kihon) : basics
643. 今度 (kondo) : this time, next time
644. 最後 (saigo) : last
645. 最初 (saisho) : first, outset
646. 準備 (junbi) : preparation, arrangement
647. 進む (susumu) : advance, move forward
648. 直接 (chokusetsu) : directly
649. 特に (tokuni) : specially, particularly
650. 届く (todoku) : reach, be received
Day 66
651. なぜ (naze) : why
652. 並ぶ (narabu) : line up, be parallel
653. 運ぶ (hakobu) : carry, transport
654. 直す (naosu) : repair, fix
655. 反対 (hantai) : oppose, object
656. 場合 (baai) : situation, case
657. 詳しい (kuwashii) : detailed
658. いたずら (itazura) : mischief, prank
659. お祝い (oiwai) : celebrate
660. くし (kushi) : comb
Day 67
661. こぼれる (koboreru) : spill, overflow
662. 伝える (tsutaeru) : convey, transmit
663. 膝 (hiza) : knee
664. 肘 (hiji) : elbow
665. 枕 (makura) : pillow
666. 建物 (tatemono) : building, structure
667. 道路 (douro) : road
668. 四つ角 (yotsukado) : intersection
669. 曲がり角 (magarikado) : corner (to turn)
670. 警察 (keisatsu) : police
Day 68
671. 空気 (kuuki) : air, atmosphere
672. スポーツ (supo-tsu) : sport
673. チャンス (chansu) : chance
674. クリーニング (kuri-ningu) : dry cleaning
675. サービス (sa-bisu) : service, on the house
676. グループ (guru-pu) : group
677. 自宅 (jitaku) : one’s house, one’s home
678. 家庭 (katei) : home, family
679. 期間 (kikan) : term, period
680. 年度 (nendo) : year, school year
Day 69
681. 経験 (keiken) : experience, knowledge
682. 安全 (anzen) : safety, security
683. 危険 (kiken) : danger, dangerous
684. 注意 (chuui) : attention, care
685. 成功 (seikou) : success
686. 努力 (doryoku) : endeavor, effort
687. 説明 (setsumei) : explanation, description
688. 地震 (jishin) : earthquake
689. 手術 (shujutsu) : surgical operation
690. 火傷 (yakedo) : burn
Day 70
691. 課題 (kadai) : task, assignment
692. 子 (ko) : young child, kid
693. 確認 (kakunin) : confirmation
694. 実際 (jissai) : reality, actual state
695. 国際 (kokusai) : international (used in compound nouns)
696. 会議 (kaigi) : conference, meeting
697. 提案 (teian) : proposition, proposal
698. 事務所 (jimusho) : office, one’s place of business
699. 教授 (kyouju) : professor
700. 世紀 (seiki) : century
Day 71
701. あちこち (achikochi) : all over, here and there
702. そちら (sochira) : there, that way (polite)
703. あちら (achira) : over there, that way (polite)
704. もし (moshi) : if, in case of
705. うるさい (urusai) : noisy, annoying
706. 固い (katai) : stiff, tight
707. 深い (fukai) : deep, profound
708. 面白い (omoshiroi) : interesting, amusing
709. 全く (mattaku) : entirely, truly
710. 半分 (hanbun) : half
Day 72
711. 普通 (futsuu) : normal, regular
712. 分 (bun) : amount, share
713. 文化 (bunka) : culture
714. 毎日 (mainichi) : every day
715. 気を付ける (kiwotsukeru) : be careful about, pay attention to
716. 守る (mamoru) : protect, observe
717. もちろん (mochiron) : of course
718. やはり (yahari) : as expected
719. いくら (ikura) : how much (money)
720. よろしく (yoroshiku) : one’s regards
Day 73
721. どなた (donata) : who (polite)
722. 許す (yurusu) : permit, forgive
723. 分ける (wakeru) : divide, share
724. 自然 (shizen) : nature
725. アパート (apa-to) : apartment, flat
726. ホテル (hoteru) : hotel
727. パソコン (pasokon) : personal computer
728. うまい (umai) : good at
729. 明るい (akarui) : bright, cheerful
730. 急ぐ (isogu) : hurry, do quickly
Day 74
731. 歌 (uta) : song
732. 中学校 (chuugakkou) : junior high school
733. テスト (tesuto) : test
734. ポスト (posuto) : postbox, mailbox
735. ハンカチ (hankachi) : handkerchief
736. 髪 (kami) : hair, hairstyle
737. 帽子 (boushi) : hat, cap
738. 被る (kaburu) : wear, put on (on one’s head)
739. ブラウス (burausu) : blouse
740. 週末 (shuumatsu) : weekend
Day 75
741. 先週 (senshuu) : last week
742. 再来週 (saraishuu) : the week after next
743. いつか (itsuka) : some time, some day
744. 宿題 (shukudai) : homework
745. 鍵 (kagi) : key, lock
746. 傘 (kasa) : umbrella, parasol
747. 乗り換える (norikaeru) : change, transfer
748. 向かう (mukau) : face, head toward
749. 本屋 (honya) : bookstore (colloquial)
750. お茶 (ocha) : tea (polite)
Day 76
751. 改札口 (kaisatsuguchi) : ticket gate
752. 晴れ (hare) : fine weather, clear sky
753. バス停 (basutei) : bus stop
754. 曇り (kumori) : cloudy weather
755. 塩 (shio) : salt
756. たくさん (takusan) : a lot, in large quantity
757. 大嫌い (daikirai) : hate
758. 中 (naka) : inside, middle
759. 二階 (nikai) : second floor, upstairs
760. 無くす (nakusu) : lose, get rid of
Day 77
761. まあまあ (maamaa) : OK, not bad
762. 黄色 (kiiro) : yellow color
763. ランチ (ranchi) : lunch (loan word)
764. 魚 (sakana) : fish
765. 味 (aji) : taste, flavor
766. りんご (ringo) : apple
767. みかん (mikan) : tangerine
768. 皿 (sara) : plate, counter (for plates or helpings)
769. コーヒー (ko-hi-) : coffee
770. コップ (koppu) : cup, glass
Day 78
771. 二人 (futari) : two persons
772. 止む (yamu) : stop, cease
773. 九 (kyuu) : nine
774. 昼間 (hiruma) : daytime, during the day
775. いつ頃 (itsugoro) : about when, about what time
776. 字 (ji) : (individual) character, letter
777. 七 (nana) : seven (Chinese origin)
778. お釣り (otsuri) : change (of money)
779. 名字 (myouji) : surname, family name
780. おじ (oji) : (one’s own) uncle
Day 79
781. おば (oba) : (one’s own) aunt
782. 祖父 (sofu) : grandfather (formal)
783. 祖母 (sobo) : grandmother (formal)
784. 大事 (daiji) : importance
785. 見方 (mikata) : view, perspective
786. 鳥 (tori) : bird, poultry
787. 犬 (inu) : dog
788. 返事 (henji) : reply, answer, response
789. また (mata) : again, also, or
790. 年間 (nenkan) : period of one year
Day 80
791. 青 (ao) : blue, green
792. 赤 (aka) : red color
793. 信号 (shingou) : signal, traffic light
794. 円 (en) : circle
795. 非常に (hijouni) : very, extremely
796. 複雑 (fukuzatsu) : complicated, intricate
797. 平和 (heiwa) : peace, harmony
798. 回る (mawaru) : turn round, go around
799. 若者 (wakamono) : young person, youth
800. 雪 (yuki) : snow, snowfall
Day 81
801. うまい (umai) : sweet, delicious
802. 思い出す (omoidasu) : recollect, recall
803. 聞こえる (kikoeru) : hear, be heard
804. 借りる (kariru) : borrow
805. 返す (kaesu) : return, repay
806. 受け取る (uketoru) : receive, get
807. 捨てる (suteru) : discard, abandon
808. 一緒 (issho) : together, same (colloquial)
809. 遊び (asobi) : play, amusement
810. 移す (utsusu) : move, transfer
Day 82
811. 大きさ (ookisa) : size, dimension
812. 考え (kangae) : thought, idea
813. 空港 (kuukou) : airport (for public transportation)
814. 出発 (shuppatsu) : departure, starting
815. 地図 (chizu) : map, atlas
816. 運転 (unten) : drive
817. 降りる (oriru) : get off, land
818. ガス (gasu) : gas (loan word)
819. 必ず (kanarazu) : without exception, always
820. カメラ (kamera) : camera
Day 83
821. 通う (kayou) : go to and from, frequent a place
822. 急に (kyuuni) : suddenly, unexpectedly
823. サラリーマン (sarari-man) : office worker, company employee
824. 給料 (kyuuryou) : salary, pay
825. 曲 (kyoku) : piece of music
826. 切れる (kireru) : cut well, be sharp
827. 正しい (tadashii) : correct, righteous
828. 苦しい (kurushii) : painful, agonizing
829. 細かい (komakai) : minute, fine
830. 静か (shizuka) : quiet, tranquil
Day 84
831. 健康 (kenkou) : health
832. ゴルフ (gorufu) : golf
833. コース (ko-su) : course, route
834. 頼む (tanomu) : order, ask for
835. 困る (komaru) : be in trouble, not know what to do
836. ずっと (zutto) : all the time, all through
837. 例えば (tatoeba) : for example
838. つもり (tsumori) : intention, purpose
839. しばらく (shibaraku) : a little while, a while
840. 紹介 (shoukai) : introduction
Day 85
841. 小学校 (shougakkou) : elementary school
842. 公園 (kouen) : park, public garden
843. 中学 (chuugaku) : junior high
844. 成績 (seiseki) : results, grade
845. 教科書 (kyoukasho) : textbook, schoolbook
846. 席 (seki) : seat, one’s place
847. 教室 (kyoushitsu) : classroom, class
848. 教師 (kyoushi) : teacher, instructor
849. 試験 (shiken) : exam
850. 合格 (goukaku) : pass an examination
Day 86
851. 数学 (suugaku) : mathematics
852. 数字 (suuji) : numeric characters
853. 音楽 (ongaku) : music
854. 食事 (shokuji) : meal
855. 壁 (kabe) : wall, partition
856. 信じる (shinjiru) : believe, trust
857. 育てる (sodateru) : bring up, raise
858. 倒れる (taoreru) : fall over
859. 落とす (otosu) : drop
860. 代わる (kawaru) : substitute, be substituted for
Day 87
861. タクシー (takushi-) : taxi
862. 確か (tashika) : for sure, for certain
863. 立てる (tateru) : stand, set up
864. 中学生 (chuugakusei) : junior high school student
865. 売れる (ureru) : sell, be in demand
866. 着く (tsuku) : arrive at, reach
867. 決まる (kimaru) : be decided
868. 飾る (kazaru) : decorate
869. 殺す (korosu) : kill
870. 下げる (sageru) : lower, turn down
Day 88
871. 贈る (okuru) : offer, give
872. 訪ねる (tazuneru) : visit, go to see
873. 打つ (utsu) : hit, strike
874. 相談 (soudan) : consultation, advice
875. 玄関 (genkan) : entrance, door
876. 兄弟 (kyoudai) : sibling
877. 長男 (chounan) : eldest son
878. 高さ (takasa) : height
879. 用 (you) : things to do
880. 時代 (jidai) : age, era
Day 89
881. 位置 (ichi) : position, location
882. 季節 (kisetsu) : season
883. 穴 (ana) : hole
884. 裏 (ura) : the back, the reverse side
885. 島 (shima) : island (Japanese origin)
886. 海岸 (kaigan) : seashore, coast
887. ガラス (garasu) : glass (material)
888. 自然 (shizen) : natural
889. 風 (kaze) : wind
890. 科学 (kagaku) : science
Day 90
891. 太陽 (taiyou) : sun
892. 台風 (taifuu) : typhoon
893. 北 (kita) : north
894. 馬 (uma) : horse
895. 牛肉 (gyuuniku) : beef
896. 雑誌 (zasshi) : magazine, journal
897. 小説 (shousetsu) : novel
898. 大使館 (taishikan) : embassy
899. 故障 (koshou) : malfunction, breakdown
900. 温度 (ondo) : temperature
Day 91
901. 何か (nanika) : something, some
902. 向こう (mukou) : over there, on the other side
903. 真ん中 (mannaka) : center, middle (casual)
904. 遠く (tooku) : far away, at a distance
905. 横 (yoko) : side, width across
906. つまらない (tsumaranai) : boring, dull
907. 素晴らしい (subarashii) : excellent, wonderful
908. 毎年 (maitoshi/ mainen) : every year (colloquial)
909. 来月 (raigetsu) : next month
910. 日時 (nichiji) : date and time
Day 92
911. 夕方 (yuugata) : early evening, at dusk
912. 通る (tooru) : pass, go through
913. 自動車 (jidousha) : automobile
914. 慣れる (nareru) : grow accustomed to, get used to
915. 撮る (toru) : take (a photograph), film
916. やっと (yatto) : at last, finally
917. どんどん (dondon) : knock, bang
918. 並べる (naraberu) : line up, arrange
919. 逃げる (nigeru) : escape, run away
920. 渡す (watasu) : hand over, give
Day 93
921. 値段 (nedan) : price
922. 両方 (ryouhou) : both
923. 約束 (yakusoku) : promise, vow
924. 一部 (ichibu) : part
925. ラジオ (rajio) : radio
926. 入院 (nyuuin) : be hospitalized
927. ニュース (nyu-su) : news
928. 旅行 (ryokou) : travel, trip
929. 用意 (youi) : preparation
930. 伸びる (nobiru) : stretch, grow
Day 94
931. パーティー (pa-ti-) : party
932. ビール (bi-ru) : beer
933. 早く (hayaku) : early, soon
934. 番組 (bangumi) : program
935. ビデオ (bideo) : video
936. 増やす (fuyasu) : increase
937. 振る (furu) : wave, shake
938. 迎える (mukaeru) : welcome, receive (a visitor)
939. 無理 (muri) : unreasonable, impossible
940. 珍しい (mezurashii) : rare, scarce
Day 95
941. 有名 (yuumei) : famous
942. 喜ぶ (yorokobu) : be happy, be delighted
943. 留学 (ryuugaku) : study abroad
944. 料理 (ryouri) : cooking
945. 野菜 (yasai) : vegetable
946. 分かれる (wakareru) : be divided, split off
947. 特別 (tokubetsu) : special
948. 理由 (riyuu) : reason, excuse
949. 自由 (jiyuu) : freedom
950. 方向 (houkou) : direction, course
Day 96
951. 残る (nokoru) : remain, be left over
952. ビル (biru) : building
953. まとめる (matomeru) : gather together, put in order
954. 流れる (nagareru) : flow, run
955. セーター (se-ta-) : sweater
956. シャツ (shatsu) : shirt
957. 洗濯 (sentaku) : laundry, washing
958. 間違える (machigaeru) : make a mistake, fail at
959. アイスクリーム (aisukuri-mu) : ice cream
960. 乾く (kawaku) : become dry
Day 97
961. 冷める (sameru) : cool off
962. 色々 (iroiro) : a variety of
963. 持って行く (motteiku) : take, bring
964. 着替える (kigaeru) : change clothes
965. 石鹸 (sekken) : soap
966. 野球 (yakyuu) : baseball
967. 昼食 (chyuushoku) : lunch
968. 朝食 (choushoku) : breakfast
969. 眠る (nemuru) : sleep, lie idle
970. 初め (hajime) : beginning
Day 98
971. 火 (hi) : fire, flame
972. 西 (nishi) : west, western
973. 東 (higashi) : east, eastern
974. 南 (minami) : south
975. 夕食 (yuushoku) : supper, dinner
976. なかなか (nakanaka) : rather, pretty
977. 励ます (hagemasu) : encourage, cheer up
978. 涙 (namida) : tear
979. 夢 (yume) : dream
980. 職場 (shokuba) : place of work, office
Day 99
981. 隣 (tonari) : next to, next door
982. マンション (manshon) : apartment, residential building
983. エレベーター (erebe-ta-) : elevator
984. 窓 (mado) : window
985. 押す (osu) : push, press down
986. 入学 (nyuugaku) : enter a school, matriculate
987. 戸 (to) : door, sliding door
988. 通り (toori) : street, road
989. 亡くなる (nakunaru) : die, pass away
990. 夫婦 (fuufu) : husband and wife, married couple
Day 100
991. 女性 (josei) : woman, female (formal)
992. 森 (mori) : forest
993. トラック (torakku) : truck
994. レコード (reko-do) : record
995. 熱 (netsu) : heat, fever
996. ページ (pe-ji) : page
997. 踊る (odoru) : dance
998. 長さ (nagasa) : length
999. 厚さ (atsusa) : thickness
1000. 秘密 (himitsu) : secret, privacy
")

(defun pen-abbrev-define-japanese ()
  (interactive)
  (let ((abbrevs
         (loop for line in
               (-filter-not-empty-string
                (str2lines
                 (snc "sed -n \"/^[0-9]/p\""
                      japanese-words)))
               collect
               (let ((tp
                      (s-split " " line)))
                 (list (s-replace-regexp
                        "(\\(.*\\))"
                        "\\1"
                        (third tp))
                       (second tp))))))

    (loop for ab in abbrevs
          do
          (progn
            (comment (define-abbrev global-abbrev-table
                       (first ab)
                       (second ab)))
            ;; j:japanese-org-mode
            (define-abbrev japanese-org-mode-abbrev-table
              (first ab)
              (second ab))))))

(pen-abbrev-define-japanese)

(add-hook 'org-mode-hook #'abbrev-mode)


;; A dynamic abbrev
(defun my-current-time ()
  (insert (format-time-string "%T")))

;; This makes a hook to a function
(define-abbrev global-abbrev-table "medyn" "" 'my-current-time)

(provide 'pen-abbrev)
