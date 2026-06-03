# Hướng dẫn sử dụng `superpower-custom` (cho Cline)

Bản port của [obra/superpowers](https://github.com/obra/superpowers) được tuỳ biến cho **Cline (extension VSCode)**, chạy với model nội bộ **GaussO3 / GaussO4**. Tài liệu này phân tích các luồng công việc, cách dùng và các tình huống áp dụng — coi như sổ tay tham khảo khi làm việc.

---

## 1. Mô hình tư duy cốt lõi

Đây không phải một "trợ lý code" tuỳ hứng. Nó ép agent đi theo **một quy trình kỹ sư có kỷ luật**, dựa trên vài niềm tin:

- **Spec trước code** — làm rõ thiết kế trước khi viết dòng nào.
- **Plan trước implement** — chia việc thành task nhỏ, có kiểm chứng, trước khi thực thi.
- **Test trước code** (TDD) — viết test, xem nó fail, rồi mới code.
- **Root cause trước fix** — không vá triệu chứng.
- **Evidence trước claim** — không tuyên bố "xong/đã sửa" nếu chưa chạy lệnh kiểm chứng.

Hai loại "diễn viên":

| Vai trò | Quyền | Việc làm |
|---|---|---|
| **Main agent** (duy nhất) | đọc + **ghi file + chạy terminal + commit** | thực thi thật: code, test, commit, merge |
| **Subagent** | **chỉ đọc** (read-only) | khảo sát context, nghiên cứu, review — báo cáo lại; không edit/chạy/commit |

Bốn thành phần cấu thành:

- `rules/` — **bootstrap rule** gắn vào mọi system prompt.
- `workflows/` — **slash command**: `/brainstorm`, `/write-plan`, `/execute-plan`.
- `skills/` — **17 skill**, nạp theo nhu cầu qua lệnh `use_skill` (không nhồi hết vào prompt).
- `docs/superpowers/` — lưu `specs/` (thiết kế) và `plans/` (kế hoạch triển khai).

---

## 2. Cơ chế hoạt động — vì sao agent "tự" làm đúng

Bạn không phải nhớ gọi từng skill. Cơ chế kích hoạt nằm ở bootstrap rule:

1. **Đầu mỗi phiên**, trước khi trả lời bất cứ điều gì (kể cả câu hỏi làm rõ), agent **luôn load `using-superpowers`** qua `use_skill`. Skill này dạy agent cách dùng các skill khác.
2. **Quy tắc ≥ 1%:** nếu có *từ 1% khả năng* yêu cầu của bạn khớp mô tả của một skill → agent **bắt buộc** nạp và làm theo skill đó. (Nếu nạp xong thấy không hợp thì bỏ.)
3. **Thứ tự ưu tiên khi mâu thuẫn:**
   1. Lệnh trực tiếp của bạn (và `CLAUDE.md`/`AGENTS.md`) — cao nhất
   2. Skill của superpower
   3. Hành vi mặc định của model
   → Bạn nói "đừng dùng TDD" thì agent nghe bạn, dù skill bảo "luôn TDD".
4. **Skill nào trước:** *process skill* (brainstorming, debugging) chạy trước để quyết định *cách tiếp cận*, rồi mới tới *implementation skill*.
   - "Build X" → brainstorming trước.
   - "Fix bug" → systematic-debugging trước.
5. **Rigid vs Flexible:** skill kiểu rigid (TDD, debugging) phải theo *đúng từng chữ*; skill kiểu flexible (mẫu thiết kế) thì vận dụng linh hoạt. Bản thân skill sẽ nói rõ nó thuộc loại nào.

> Lệnh của bạn nói **WHAT** (làm gì), không phải **HOW** (làm thế nào). "Thêm X" / "Sửa Y" **không** đồng nghĩa với "bỏ qua quy trình".

Vì skill viết theo "ngôn ngữ" của các agent platform khác, `using-superpowers` có bảng ánh xạ sang công cụ Cline: `Read`→`read_file`, `Write/Edit`→`editor`, `Bash`→`execute_command`, `Grep`→`search_files`, `Glob`→`list_files`, `Task`→dispatch subagent read-only, `WebFetch`→`fetch_web`, `Skill`→`use_skill`.

---

## 3. Vòng đời chuẩn (the golden path)

```
   /brainstorm          /write-plan          /execute-plan              finishing
 ┌───────────┐  spec   ┌───────────┐  plan   ┌────────────────────┐    ┌──────────────┐
 │ Thiết kế  │ ──────▶ │ Lập kế    │ ──────▶ │ Thực thi từng task │ ─▶ │ Merge / PR / │
 │ (HARD     │  được   │ hoạch     │  được   │ (TDD + review)     │    │ cleanup      │
 │  GATE)    │  duyệt  │           │  duyệt  │                    │    │              │
 └───────────┘         └───────────┘         └────────────────────┘    └──────────────┘
      │                      │                        │                       │
   spec.md              plan.md                 commits theo task          branch xong
 (docs/.../specs)   (docs/.../plans)         (1 commit / 1 task)
```

Artifact sinh ra dọc đường: **file spec** → **file plan** → **feature branch sạch** → **chuỗi commit nhỏ** → **PR/merge**. Mỗi mắt xích có một "cổng" (gate) phải qua mới đi tiếp.

---

## 4. Ba slash command

### `/brainstorm` — biến ý tưởng thành spec
- Nạp skill `brainstorming`.
- **HARD GATE:** *không* code, *không* scaffold, *không* gọi skill triển khai cho tới khi đã trình bày thiết kế và **bạn duyệt**. Áp dụng cho **mọi** dự án, kể cả "đơn giản".
- Checklist: khảo sát context → hỏi từng câu một → đề xuất 2–3 hướng kèm trade-off → trình bày thiết kế theo từng phần để bạn duyệt → ghi spec ra `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` → tự rà soát spec → bạn review file spec → chuyển sang `writing-plans`.
- Nếu dự án quá lớn (nhiều subsystem độc lập) → agent đề nghị **tách nhỏ** thành nhiều sub-project, mỗi cái một vòng spec → plan → implement riêng.

### `/write-plan` — biến spec thành kế hoạch thực thi
- Nạp skill `writing-plans`. **Điều kiện:** phải có spec đã duyệt (thường từ `/brainstorm`); nếu chưa có → agent hỏi hoặc gợi ý chạy `/brainstorm` trước.
- Plan là **bản hợp đồng (contract)**, không phải kịch bản (script): chỉ chứa thứ executor *không tự suy ra được* — đường dẫn file, **code test (chính là hợp đồng)**, chữ ký interface/API, định dạng output, lệnh verify + output kỳ vọng, commit message. Code suy ra được từ spec thì *để trong spec*.
- **Granularity:** mỗi step là một hành động 2–5 phút ("viết test fail" / "chạy cho fail" / "code tối thiểu để pass" / "chạy cho pass" / "commit").
- **Định dạng:** ≤ 6 task → **1 file**; > 6 task → **folder nhiều file** (`README.md` + `task-NN-<slug>.md`). Folder cho phép executor mở từng task một, không phải gánh cả plan trong context — rất hợp với agent một-context như Cline.

### `/execute-plan` — thực thi kế hoạch
- **Điều kiện:** có plan đã duyệt.
- Agent hỏi bạn chọn 1 trong 2 chế độ:
  - **`executing-plans`** — thực thi trực tiếp, có **checkpoint với bạn** (dùng khi không có subagent).
  - **`subagent-driven-development`** — dùng subagent để research + review giữa các task, **giữ context của main agent sạch** (khuyến nghị khi có subagent — chất lượng cao hơn rõ rệt).
- Với plan nhiều file: **không** nạp hết task vào context — đọc `README.md` để định hướng, rồi mở đúng `task-NN` đang làm; xong, commit, rồi *ngừng tham chiếu* và mở task kế tiếp.

---

## 5. Mô hình subagent read-only (điểm đặc thù Cline)

Đây là chỗ bản custom khác bản gốc nhiều nhất.

- Subagent **chỉ được đọc**: `read_file`, `search_files`, `list_files`, `fetch_web`. **Không** edit, **không** chạy test, **không** commit.
- Ba vai trò chính của subagent:
  1. **Researcher** — khảo sát codebase *trước khi* main agent code (trả về path/line, pattern nên theo/tránh, dependency, gotcha, đề xuất hướng).
  2. **Reviewer** — sau khi code: một subagent kiểm *spec compliance*, một subagent kiểm *code quality*.
  3. **Parallel research** — nhiều subagent khảo sát các vùng độc lập cùng lúc.
- **Nguyên tắc vàng:** main agent **paste thẳng nội dung task vào prompt** cho subagent — không bắt subagent tự mở file plan. Subagent không kế thừa lịch sử hội thoại của bạn; bạn "đóng gói" đúng thứ nó cần.
- Lý do: tiết kiệm/giữ sạch context của main agent (quan trọng với token của GaussO), và buộc kết quả của subagent phải tập trung.

Vòng lặp một task trong `subagent-driven-development`:
**researcher (subagent) → main agent implement theo TDD → spec reviewer (subagent) → quality reviewer (subagent) → commit.**

---

## 6. Toàn bộ skill — phân theo vai trò & khi nào dùng

| Skill | Khi nào kích hoạt | Ghi chú |
|---|---|---|
| `using-superpowers` | đầu **mọi** phiên | dạy cách tìm & dùng skill; quy tắc ≥1% |
| `brainstorming` | trước **mọi** việc sáng tạo (tính năng/component/đổi hành vi) | HARD GATE: không code đến khi duyệt design |
| `writing-plans` | khi đã có spec, trước khi đụng code | plan = contract; chia task 2–5 phút |
| `creating-feature-branch` | trước khi thực thi plan / bắt đầu viết code | tree sạch → branch → baseline test pass |
| `test-driven-development` | khi implement **bất kỳ** feature/bugfix | **Iron law:** không có code production nếu chưa có test fail |
| `executing-plans` | có plan, thực thi với checkpoint (không subagent) | đọc plan critically trước khi chạy |
| `subagent-driven-development` | có plan, các task độc lập, có subagent | research + review qua subagent |
| `systematic-debugging` | gặp **bất kỳ** bug/test fail/hành vi lạ | **Iron law:** không fix khi chưa tìm root cause; có kèm root-cause-tracing, defense-in-depth, condition-based-waiting |
| `dispatching-parallel-agents` | ≥ 2–3 vùng cần khảo sát độc lập | bung nhiều subagent read-only song song |
| `requesting-code-review` | sau mỗi task / trước merge / xong feature lớn | dispatch subagent review theo `BASE_SHA..HEAD_SHA` |
| `receiving-code-review` | khi nhận feedback review | đòi hỏi rigor, không "gật cho qua" cũng không sửa mù |
| `verification-before-completion` | trước khi tuyên bố xong/đã sửa/đang pass | **Iron law:** không claim nếu chưa chạy lệnh verify trong message này |
| `finishing-a-development-branch` | xong việc, test pass, cần tích hợp | verify test → trình bày lựa chọn merge/PR/cleanup |
| `creating-skills` | đóng gói source thành skill tái dùng | tạo BP dạng **skill** |
| `creating-rules` | cần quy tắc luôn bật cho project | tạo BP dạng **rule** (`.clinerules/*.md`) |
| `creating-workflows` | cần quy trình nhiều bước gọi bằng slash command | tạo BP dạng **workflow** |
| `creating-hooks` | cần kích hoạt theo sự kiện vòng đời | tạo BP dạng **hook** (TaskStart, PreToolUse, PostToolUse…) |

---

## 7. Bốn "iron law" cần nhớ

1. **Brainstorming HARD GATE** — không code đến khi design được bạn duyệt.
2. **TDD** — `NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST`. Lỡ viết code trước test? Xoá, làm lại.
3. **Debugging** — `NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST`.
4. **Verification** — `NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE`.

---

## 8. Các tình huống sử dụng cụ thể (when X → do Y)

### TH1 — Làm một tính năng mới của AXon (từ con số 0)
Bạn: mô tả tính năng → gõ `/brainstorm`.
Agent: hỏi từng câu, đề xuất 2–3 hướng, trình bày design, ghi spec; **chờ bạn duyệt** → `/write-plan` tạo plan task nhỏ → `/execute-plan` (chọn subagent-driven) → `creating-feature-branch` → từng task TDD + review → `finishing-a-development-branch`.
Output: spec, plan, branch, commits, PR.

### TH2 — Yêu cầu nhỏ / sửa nhẹ
Vẫn qua brainstorm **rút gọn** (design vài câu) rồi mới làm. "Đơn giản" chính là chỗ giả định sai gây tốn công nhất.

### TH3 — Dự án lớn, nhiều subsystem
Trong `/brainstorm`, agent phát hiện phạm vi quá rộng → đề nghị **decompose** thành các sub-project độc lập, làm lần lượt từng vòng spec → plan → implement.

### TH4 — Sửa bug / test fail
Gõ mô tả lỗi. Agent nạp `systematic-debugging`: **Phase 1 tìm root cause trước**, không đề xuất fix khi chưa hiểu nguyên nhân → sửa → `verification-before-completion` (chạy lệnh, đọc output, mới được nói "đã sửa").

### TH5 — Khảo sát codebase lạ / chọn thư viện
Có ≥ 2–3 hướng độc lập → `dispatching-parallel-agents`: nhiều subagent read-only khảo sát song song, main agent tổng hợp rồi mới quyết.

### TH6 — Trước khi merge
`requesting-code-review`: dispatch subagent review diff `BASE_SHA..HEAD_SHA`, báo lỗi theo mức độ; lỗi critical chặn merge.

### TH7 — Nhận feedback review
`receiving-code-review`: đánh giá từng góp ý bằng lý lẽ kỹ thuật, không sửa mù cũng không phản đối cho có; điểm nào mơ hồ thì làm rõ.

### TH8 — Hoàn tất & tích hợp
`finishing-a-development-branch`: **verify test pass trước** (fail thì dừng), rồi trình bày lựa chọn merge / tạo PR / giữ branch / bỏ, và dọn dẹp.

### TH9 — Đóng gói kinh nghiệm thành BP (đầu ra cuộc thi)
Sau khi giải quyết một việc lặp lại, dùng nhóm `creating-*`:
- `creating-skills` → một skill mới (kèm `references/`, `templates/`, `scripts/` nếu cần).
- `creating-rules` → quy tắc luôn bật cho project.
- `creating-workflows` → slash command quy trình.
- `creating-hooks` → hook theo sự kiện.
→ Đưa lên AXon, nộp cho cuộc thi.

---

## 9. Cách áp dụng cho cuộc thi VibeCheck (gợi ý vận hành 2 tuần)

- **Mỗi mảng việc** đi trọn vòng `/brainstorm → /write-plan → /execute-plan → finishing`. Đừng "vibe" thẳng vào code — chính kỷ luật này tạo ra spec/plan/commit sạch để kể chuyện khi demo.
- **Cứ làm xong một mảng có giá trị lặp lại → dừng lại tạo BP** bằng `creating-*`. Đây là output được chấm điểm, nên hãy coi việc tạo BP là một "task" chính thức trong plan, không phải việc làm thêm cuối ngày.
- **Tận dụng subagent read-only** cho mọi việc khảo sát/đọc hiểu để tiết kiệm context (token) của GaussO cho main agent.
- **Viết `description` của skill/rule cho rõ** — vì cơ chế trigger dựa trên việc request khớp mô tả; mô tả mơ hồ thì skill không tự kích hoạt.
- **Chọn plan nhiều file** khi các task độc lập, để mỗi lần chỉ tải một task vào context.

---

## 10. Red flags — dấu hiệu đang "tự bào chữa" (đừng làm)

Những suy nghĩ sau là tín hiệu **DỪNG**, không phải lý do để bỏ quy trình:

- "Việc này đơn giản quá, khỏi cần design." → vẫn brainstorm (design ngắn cũng được).
- "Plan dài quá, thôi code thẳng từ spec." → không; plan giữ lại bước verify & commit boundary có lý do.
- "Task này hiển nhiên, khỏi theo từng step." → step nhỏ là để bắt lỗi ẩn.
- "Mình nhớ skill này rồi." → skill có thể đã đổi; vẫn `use_skill` bản hiện tại.
- "Để mình kiểm tra file/git một chút trước đã." → check skill **trước** mọi hành động.
- "Test chắc chắn sẽ pass, khỏi chạy." → vẫn phải chạy mới được claim.

---

## 11. Cheat-sheet

| Tình huống | Lệnh / skill |
|---|---|
| Bắt đầu việc mới | `/brainstorm` |
| Có spec, cần kế hoạch | `/write-plan` |
| Có plan, bắt đầu code | `/execute-plan` → chọn subagent-driven |
| Gặp bug | mô tả lỗi → `systematic-debugging` |
| Cần khảo sát nhiều vùng | `dispatching-parallel-agents` |
| Sắp merge | `requesting-code-review` |
| Sắp nói "xong" | `verification-before-completion` |
| Đóng việc | `finishing-a-development-branch` |
| Tạo BP | `creating-skills` / `-rules` / `-workflows` / `-hooks` |

**Một câu tóm tắt:** *spec → plan → branch → (test → code → review → commit) ×N → merge → đóng gói thành BP.*
