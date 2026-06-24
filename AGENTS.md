<!-- TRELLIS:START -->
# Trellis Instructions

These instructions are for AI assistants working in this project.

This project is managed by Trellis. The working knowledge you need lives under `.trellis/`:

- `.trellis/workflow.md` — development phases, when to create tasks, skill routing
- `.trellis/spec/` — package- and layer-scoped coding guidelines (read before writing code in a given layer)
- `.trellis/workspace/` — per-developer journals and session traces
- `.trellis/tasks/` — active and archived tasks (PRDs, research, jsonl context)

If a Trellis command is available on your platform (e.g. `/trellis:finish-work`, `/trellis:continue`), prefer it over manual steps. Not every platform exposes every command.

If you're using Codex or another agent-capable tool, additional project-scoped helpers may live in:
- `.agents/skills/` — reusable Trellis skills
- `.codex/agents/` — optional custom subagents

Managed by Trellis. Edits outside this block are preserved; edits inside may be overwritten by a future `trellis update`.

<!-- TRELLIS:END -->

---

## 📌 Quy định bắt buộc đối với AI Assistant (Agent) về việc sử dụng Trellis

Mọi AI Assistant khi làm việc trong dự án này **bắt buộc** phải tuân thủ quy trình quản lý của Trellis:
1. **Trước khi bắt đầu thực hiện (viết code)**:
   - Kiểm tra task active bằng lệnh: `python ./.trellis/scripts/task.py current --source`.
   - Nếu chưa có task active, bắt buộc phải hỏi ý kiến người dùng và chạy lệnh để tạo + kích hoạt task:
     - Tạo task: `python ./.trellis/scripts/task.py create "Tên nhiệm vụ" --slug <slug-name>`
     - Bắt đầu task: `python ./.trellis/scripts/task.py start <slug-name>`
2. **Sau khi thực hiện xong và build thành công**:
   - Bắt buộc phải chạy lệnh ghi nhận nhật ký phiên làm việc (Session) trước khi báo cáo hoàn thành:
     - Ghi nhận: `python ./.trellis/scripts/add_session.py --title "Tiêu đề session" --summary "Tóm tắt những thay đổi" --no-commit`

*Quy định này là bắt buộc đối với tất cả các AI Agent và không được phép bỏ qua trong bất kỳ phiên hội thoại nào.*