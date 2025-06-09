# Tmux Session Manager - Example Run

## Initial Startup

```bash
$ ./tmux-manager.sh
```

## Main Menu Display

```
╔════════════════════════════════╗
║     TMUX SESSION MANAGER     ║
╚════════════════════════════════╝

📊 Active Sessions: 3
📋 Quick Overview:
   development (attached, 3 windows, 06-08 14:23)
   server-monitoring (detached, 2 windows, 06-07 09:15)
   personal-project (detached, 1 windows, 06-06 16:45)

1) 📋 List & Attach to Session
2) ➕ Create New Session
3) 📝 Rename Session
4) 🗑️  Delete Session
5) 🔧 Session Management
6) ⚙️  Configuration
7) ❓ Help
8) 🚪 Exit

Choose an option [1-8]: 
```

## Example 1: Listing and Attaching to Sessions (Option 1)

```
Choose an option [1-8]: 1
```

**With fzf installed:**
```
  ● development (attached, 3 windows, 06-08 14:23)
  ○ server-monitoring (detached, 2 windows, 06-07 09:15)
  ○ personal-project (detached, 1 windows, 06-06 16:45)
  ○ backup-scripts (detached, 1 windows, 06-05 11:30)
> ● development (attached, 3 windows, 06-08 14:23)
  4/4
> Select session to attach (Esc to cancel): 
```

**Without fzf:**
```
Available sessions:
1) development (attached, 3 windows, 06-08 14:23)
2) server-monitoring (detached, 2 windows, 06-07 09:15)
3) personal-project (detached, 1 windows, 06-06 16:45)
4) backup-scripts (detached, 1 windows, 06-05 11:30)
5) Back to menu

Select session [1-5]: 2
Attaching to session 'server-monitoring'...
[Session attached - user enters tmux environment]
```

## Example 2: Creating a New Session (Option 2)

```
Choose an option [1-8]: 2

Session Creation
1) Basic session
2) Development session (3 windows: editor, terminal, logs)
3) Custom session
Choose type [1-3]: 2

Enter session name: web-app-backend
Development session 'web-app-backend' created with 3 windows.
Attach to the new session now? [Y/n]: y
[Attaches to new session with 3 windows already set up]
```

## Example 3: Session Management (Option 5)

```
Choose an option [1-8]: 5

=== Session Management ===
1) Kill all detached sessions
2) Show detailed session info
3) List session windows
4) Duplicate session
5) Back to main menu
Choose option [1-5]: 2

=== development ===
Info: 3 windows, 1 clients, created: 2025-06-08 14:23
Windows:
  0: editor (2 panes) (active)
  1: terminal (1 panes) 
  2: logs (1 panes) 

=== server-monitoring ===
Info: 2 windows, 0 clients, created: 2025-06-07 09:15
Windows:
  0: htop (1 panes) (active)
  1: logs (1 panes) 

=== personal-project ===
Info: 1 windows, 0 clients, created: 2025-06-06 16:45
Windows:
  0: bash (1 panes) (active)

=== web-app-backend ===
Info: 3 windows, 0 clients, created: 2025-06-09 10:30
Windows:
  0: editor (1 panes) (active)
  1: terminal (1 panes) 
  2: logs (1 panes) 
```

## Example 4: Killing Detached Sessions

```
Choose option [1-5]: 1

Detached sessions:
server-monitoring
personal-project
web-app-backend
Kill all detached sessions? [y/N]: y
All detached sessions killed.
```

## Example 5: Configuration Menu (Option 6)

```
Choose an option [1-8]: 6

=== Configuration ===
1) Sort sessions: false
2) Show session info in menu: true
3) Default shell: /bin/bash
4) Save configuration
5) Reset to defaults
6) Back to main menu
Choose option [1-6]: 1
Sort sessions set to: true

Choose option [1-6]: 4
Configuration saved.

Choose option [1-6]: 6
```

## Example 6: Creating a Custom Session

```
Choose an option [1-8]: 2

Session Creation
1) Basic session
2) Development session (3 windows: editor, terminal, logs)
3) Custom session
Choose type [1-3]: 3

Enter session name: data-analysis
Enter initial directory (or press Enter for current): /home/user/datasets
Enter initial command (optional): python3 -m jupyter notebook
Custom session 'data-analysis' created.
Attach to the new session now? [Y/n]: n
```

## Example 7: Deleting a Session with Confirmation

```
Choose an option [1-8]: 4

Available sessions (with fzf):
> ● development (attached, 3 windows, 06-08 14:23)
  ○ data-analysis (detached, 1 windows, 06-09 10:35)
  2/2
> Select session to delete: 

[User selects data-analysis]

Session info: 1 windows, 0 clients, created: 2025-06-09 10:35
Are you sure you want to delete session 'data-analysis'? [y/N]: y
Session 'data-analysis' deleted.
Press Enter to continue...
```

## Example 8: Help System (Option 7)

```
Choose an option [1-8]: 7

=== Tmux Session Manager Help ===
Features:
• Create, rename, delete, and attach to tmux sessions
• Session templates for quick setup
• Detailed session information and statistics
• Bulk operations (kill detached sessions)
• Configurable sorting and display options
• FZF integration for better navigation (if installed)

Tips:
• Install 'fzf' for enhanced session selection
• Use development template for coding projects
• Configure settings in the Configuration menu
• Sessions persist until manually deleted or system reboot
Press Enter to continue...
```

## Final Exit

```
Choose an option [1-8]: 8
Goodbye!
```

---

## Key Improvements Demonstrated:

1. **Visual Appeal**: Colored output, status indicators (● for attached, ○ for detached)
2. **Rich Information**: Session details including window count, attachment status, creation time
3. **Smart Defaults**: Quick overview on main menu, confirmation prompts
4. **Flexible Creation**: Multiple session templates for different use cases
5. **Bulk Operations**: Kill multiple sessions at once
6. **Configuration**: Persistent settings that survive script restarts
7. **Better UX**: Clear navigation, helpful prompts, error handling
8. **FZF Integration**: Enhanced selection when fzf is available, fallback to numbered menus

The script maintains the simplicity of your original while adding professional-grade features and a much more polished user experience!
