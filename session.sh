#!/bin/bash

# Check for tmux
if ! command -v tmux &> /dev/null; then
    echo "tmux is not installed. Please install it first."
    exit 1
fi

# Interactive menu
show_menu() {
    echo
    echo "===================="
    echo " TMUX Session Manager"
    echo "===================="
    echo "1) List & Attach to Session"
    echo "2) Create New Session"
    echo "3) Rename Session"
    echo "4) Delete Session"
    echo "5) Exit"
    echo -n "Choose an option [1-5]: "
}

# Attach to a selected session
list_and_attach() {
    sessions=($(tmux list-sessions -F "#{session_name}" 2>/dev/null))
    if [ ${#sessions[@]} -eq 0 ]; then
        echo "No sessions found."
        return
    fi

    if command -v fzf &> /dev/null; then
        selected=$(printf "%s\n" "${sessions[@]}" | fzf --prompt="Select session to attach: ")
    else
        echo "Available sessions:"
        select session in "${sessions[@]}"; do
            if [ -n "$session" ]; then
                selected="$session"
                break
            else
                echo "Invalid choice. Try again."
            fi
        done
    fi

    if [ -n "$selected" ]; then
        tmux attach -t "$selected"
    else
        echo "No session selected."
    fi
}

# Create a new session
create_session() {
    read -p "Enter new session name: " session_name
    if [ -n "$session_name" ]; then
        tmux new -s "$session_name"
    else
        echo "Session name cannot be empty."
    fi
}

# Rename a session
rename_session() {
    sessions=($(tmux list-sessions -F "#{session_name}" 2>/dev/null))
    if [ ${#sessions[@]} -eq 0 ]; then
        echo "No sessions available to rename."
        return
    fi

    if command -v fzf &> /dev/null; then
        old_name=$(printf "%s\n" "${sessions[@]}" | fzf --prompt="Select session to rename: ")
    else
        echo "Select session to rename:"
        select session in "${sessions[@]}"; do
            if [ -n "$session" ]; then
                old_name="$session"
                break
            else
                echo "Invalid choice. Try again."
            fi
        done
    fi

    if [ -n "$old_name" ]; then
        read -p "Enter new name for session '$old_name': " new_name
        if [ -n "$new_name" ]; then
            tmux rename-session -t "$old_name" "$new_name"
            echo "Session renamed from '$old_name' to '$new_name'."
        else
            echo "New name cannot be empty."
        fi
    fi
}

# Delete a session
delete_session() {
    sessions=($(tmux list-sessions -F "#{session_name}" 2>/dev/null))
    if [ ${#sessions[@]} -eq 0 ]; then
        echo "No sessions available to delete."
        return
    fi

    if command -v fzf &> /dev/null; then
        to_delete=$(printf "%s\n" "${sessions[@]}" | fzf --prompt="Select session to delete: ")
    else
        echo "Select session to delete:"
        select session in "${sessions[@]}"; do
            if [ -n "$session" ]; then
                to_delete="$session"
                break
            else
                echo "Invalid choice. Try again."
            fi
        done
    fi

    if [ -n "$to_delete" ]; then
        read -p "Are you sure you want to delete session '$to_delete'? [y/N]: " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            tmux kill-session -t "$to_delete"
            echo "Session '$to_delete' deleted."
        else
            echo "Deletion cancelled."
        fi
    fi
}

# Main loop
while true; do
    show_menu
    read -r choice
    case "$choice" in
        1) list_and_attach ;;
        2) create_session ;;
        3) rename_session ;;
        4) delete_session ;;
        5) echo "Goodbye!"; exit 0 ;;
        *) echo "Invalid option. Please choose 1–5." ;;
    esac
done
