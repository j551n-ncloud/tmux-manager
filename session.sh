#!/bin/bash

# Enhanced Tmux Session Manager
# Features: Session info, window management, configuration, sorting, and more

# Configuration
DEFAULT_SHELL="${SHELL:-/bin/bash}"
CONFIG_FILE="$HOME/.tmux-manager.conf"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Load configuration
load_config() {
    [[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"
}

# Save configuration
save_config() {
    cat > "$CONFIG_FILE" << EOF
# Tmux Manager Configuration
DEFAULT_SHELL="$DEFAULT_SHELL"
SORT_SESSIONS="$SORT_SESSIONS"
SHOW_SESSION_INFO="$SHOW_SESSION_INFO"
EOF
}

# Check dependencies
check_dependencies() {
    if ! command -v tmux &> /dev/null; then
        echo -e "${RED}Error: tmux is not installed. Please install it first.${NC}"
        exit 1
    fi
}

# Utility functions
get_session_info() {
    local session="$1"
    local windows=$(tmux list-windows -t "$session" 2>/dev/null | wc -l)
    local clients=$(tmux list-clients -t "$session" 2>/dev/null | wc -l)
    local created=$(tmux display-message -t "$session" -p "#{session_created}")
    local created_date=$(date -d "@$created" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "Unknown")
    echo "$windows windows, $clients clients, created: $created_date"
}

get_sessions() {
    local format="#{session_name}:#{session_windows}:#{session_attached}:#{session_created}"
    tmux list-sessions -F "$format" 2>/dev/null | while IFS=':' read -r name windows attached created; do
        local status="detached"
        [[ "$attached" != "0" ]] && status="attached"
        local created_date=$(date -d "@$created" "+%m-%d %H:%M" 2>/dev/null || echo "??-?? ??:??")
        echo "$name|$windows|$status|$created_date"
    done
}

# Enhanced menu
show_menu() {
    clear
    echo -e "${CYAN}╔════════════════════════════════╗${NC}"
    echo -e "${CYAN}║     ${YELLOW}TMUX SESSION MANAGER${CYAN}     ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════╝${NC}"
    echo
    
    # Show current sessions summary
    local session_count=$(tmux list-sessions 2>/dev/null | wc -l)
    echo -e "${BLUE}📊 Active Sessions: ${GREEN}$session_count${NC}"
    
    if [[ "$SHOW_SESSION_INFO" == "true" && $session_count -gt 0 ]]; then
        echo -e "${BLUE}📋 Quick Overview:${NC}"
        get_sessions | head -3 | while IFS='|' read -r name windows status created; do
            local status_color="${GREEN}"
            [[ "$status" == "detached" ]] && status_color="${YELLOW}"
            echo -e "   ${PURPLE}$name${NC} (${status_color}$status${NC}, $windows windows, $created)"
        done
        [[ $session_count -gt 3 ]] && echo -e "   ${CYAN}... and $((session_count - 3)) more${NC}"
        echo
    fi
    
    echo -e "${GREEN}1)${NC} 📋 List & Attach to Session"
    echo -e "${GREEN}2)${NC} ➕ Create New Session"
    echo -e "${GREEN}3)${NC} 📝 Rename Session"
    echo -e "${GREEN}4)${NC} 🗑️  Delete Session"
    echo -e "${GREEN}5)${NC} 🔧 Session Management"
    echo -e "${GREEN}6)${NC} ⚙️  Configuration"
    echo -e "${GREEN}7)${NC} ❓ Help"
    echo -e "${GREEN}8)${NC} 🚪 Exit"
    echo
    echo -n "Choose an option [1-8]: "
}

# Enhanced session listing with detailed info
list_and_attach() {
    local sessions_data=($(get_sessions))
    if [ ${#sessions_data[@]} -eq 0 ]; then
        echo -e "${YELLOW}No sessions found.${NC}"
        read -p "Press Enter to continue..."
        return
    fi

    # Sort sessions if enabled
    if [[ "$SORT_SESSIONS" == "true" ]]; then
        sessions_data=($(printf "%s\n" "${sessions_data[@]}" | sort))
    fi

    if command -v fzf &> /dev/null; then
        local display_list=()
        for session_data in "${sessions_data[@]}"; do
            IFS='|' read -r name windows status created <<< "$session_data"
            local status_indicator="○"
            [[ "$status" == "attached" ]] && status_indicator="●"
            display_list+=("$status_indicator $name ($status, $windows windows, $created)")
        done
        
        local selected=$(printf "%s\n" "${display_list[@]}" | fzf --prompt="Select session to attach (Esc to cancel): " --height=40%)
        [ -z "$selected" ] && echo -e "${YELLOW}No session selected.${NC}" && return
        
        # Extract session name from selection
        local session_name=$(echo "$selected" | sed 's/^[○●] \([^ ]*\).*/\1/')
    else
        echo -e "${BLUE}Available sessions:${NC}"
        local session_names=()
        local i=1
        for session_data in "${sessions_data[@]}"; do
            IFS='|' read -r name windows status created <<< "$session_data"
            local status_color="${YELLOW}"
            [[ "$status" == "attached" ]] && status_color="${GREEN}"
            echo -e "${PURPLE}$i)${NC} ${CYAN}$name${NC} (${status_color}$status${NC}, $windows windows, $created)"
            session_names+=("$name")
            ((i++))
        done
        session_names+=("Back")
        echo -e "${PURPLE}$i)${NC} Back to menu"
        
        echo -n "Select session [1-$i]: "
        read -r choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#session_names[@]}" ]; then
            local selected_session="${session_names[$((choice-1))]}"
            [[ "$selected_session" == "Back" ]] && return
            session_name="$selected_session"
        else
            echo -e "${RED}Invalid choice.${NC}"
            return
        fi
    fi

    if [ -n "$session_name" ]; then
        echo -e "${GREEN}Attaching to session '$session_name'...${NC}"
        tmux attach -t "$session_name"
    fi
}

# Enhanced session creation with templates
create_session() {
    echo -e "${BLUE}Session Creation${NC}"
    echo "1) Basic session"
    echo "2) Development session (3 windows: editor, terminal, logs)"
    echo "3) Custom session"
    echo -n "Choose type [1-3]: "
    read -r session_type
    
    read -p "Enter session name: " session_name
    if [ -z "$session_name" ]; then
        echo -e "${RED}Session name cannot be empty.${NC}"
        return
    fi
    
    # Check if session already exists
    if tmux has-session -t "$session_name" 2>/dev/null; then
        echo -e "${RED}Session '$session_name' already exists.${NC}"
        return
    fi
    
    case "$session_type" in
        1)
            tmux new-session -d -s "$session_name"
            echo -e "${GREEN}Basic session '$session_name' created.${NC}"
            ;;
        2)
            tmux new-session -d -s "$session_name" -n "editor"
            tmux new-window -t "$session_name" -n "terminal"
            tmux new-window -t "$session_name" -n "logs"
            tmux select-window -t "$session_name:editor"
            echo -e "${GREEN}Development session '$session_name' created with 3 windows.${NC}"
            ;;
        3)
            read -p "Enter initial directory (or press Enter for current): " init_dir
            read -p "Enter initial command (optional): " init_cmd
            
            local create_cmd="tmux new-session -d -s \"$session_name\""
            [ -n "$init_dir" ] && create_cmd+=" -c \"$init_dir\""
            [ -n "$init_cmd" ] && create_cmd+=" \"$init_cmd\""
            
            eval "$create_cmd"
            echo -e "${GREEN}Custom session '$session_name' created.${NC}"
            ;;
        *)
            echo -e "${RED}Invalid session type.${NC}"
            return
            ;;
    esac
    
    read -p "Attach to the new session now? [Y/n]: " attach_now
    if [[ ! "$attach_now" =~ ^[Nn]$ ]]; then
        tmux attach -t "$session_name"
    fi
}

# Session management menu
session_management() {
    while true; do
        echo -e "\n${CYAN}=== Session Management ===${NC}"
        echo "1) Kill all detached sessions"
        echo "2) Show detailed session info"
        echo "3) List session windows"
        echo "4) Duplicate session"
        echo "5) Back to main menu"
        echo -n "Choose option [1-5]: "
        read -r mgmt_choice
        
        case "$mgmt_choice" in
            1) kill_detached_sessions ;;
            2) show_detailed_info ;;
            3) list_session_windows ;;
            4) duplicate_session ;;
            5) break ;;
            *) echo -e "${RED}Invalid option.${NC}" ;;
        esac
    done
}

kill_detached_sessions() {
    local detached=$(tmux list-sessions -F "#{session_name} #{session_attached}" 2>/dev/null | grep " 0$" | cut -d' ' -f1)
    if [ -z "$detached" ]; then
        echo -e "${YELLOW}No detached sessions found.${NC}"
        return
    fi
    
    echo -e "${BLUE}Detached sessions:${NC}"
    echo "$detached"
    read -p "Kill all detached sessions? [y/N]: " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo "$detached" | xargs -I {} tmux kill-session -t {}
        echo -e "${GREEN}All detached sessions killed.${NC}"
    fi
}

show_detailed_info() {
    local sessions=($(tmux list-sessions -F "#{session_name}" 2>/dev/null))
    [ ${#sessions[@]} -eq 0 ] && echo -e "${YELLOW}No sessions found.${NC}" && return
    
    for session in "${sessions[@]}"; do
        echo -e "\n${CYAN}=== $session ===${NC}"
        echo -e "${BLUE}Info:${NC} $(get_session_info "$session")"
        echo -e "${BLUE}Windows:${NC}"
        tmux list-windows -t "$session" -F "  #{window_index}: #{window_name} (#{window_panes} panes) #{?window_active,(active),}"
    done
}

# Configuration menu
configuration_menu() {
    load_config
    while true; do
        echo -e "\n${CYAN}=== Configuration ===${NC}"
        echo -e "1) Sort sessions: ${GREEN}${SORT_SESSIONS:-false}${NC}"
        echo -e "2) Show session info in menu: ${GREEN}${SHOW_SESSION_INFO:-false}${NC}"  
        echo -e "3) Default shell: ${GREEN}${DEFAULT_SHELL}${NC}"
        echo "4) Save configuration"
        echo "5) Reset to defaults"
        echo "6) Back to main menu"
        echo -n "Choose option [1-6]: "
        read -r config_choice
        
        case "$config_choice" in
            1) 
                [[ "$SORT_SESSIONS" == "true" ]] && SORT_SESSIONS="false" || SORT_SESSIONS="true"
                echo -e "${GREEN}Sort sessions set to: $SORT_SESSIONS${NC}"
                ;;
            2)
                [[ "$SHOW_SESSION_INFO" == "true" ]] && SHOW_SESSION_INFO="false" || SHOW_SESSION_INFO="true"
                echo -e "${GREEN}Show session info set to: $SHOW_SESSION_INFO${NC}"
                ;;
            3)
                read -p "Enter default shell path: " new_shell
                [ -n "$new_shell" ] && DEFAULT_SHELL="$new_shell"
                ;;
            4)
                save_config
                echo -e "${GREEN}Configuration saved.${NC}"
                ;;
            5)
                SORT_SESSIONS="false"
                SHOW_SESSION_INFO="false" 
                DEFAULT_SHELL="${SHELL:-/bin/bash}"
                echo -e "${GREEN}Configuration reset to defaults.${NC}"
                ;;
            6) break ;;
            *) echo -e "${RED}Invalid option.${NC}" ;;
        esac
    done
}

# Help menu
show_help() {
    echo -e "\n${CYAN}=== Tmux Session Manager Help ===${NC}"
    echo -e "${YELLOW}Features:${NC}"
    echo "• Create, rename, delete, and attach to tmux sessions"
    echo "• Session templates for quick setup"
    echo "• Detailed session information and statistics"
    echo "• Bulk operations (kill detached sessions)"
    echo "• Configurable sorting and display options"
    echo "• FZF integration for better navigation (if installed)"
    echo
    echo -e "${YELLOW}Tips:${NC}"
    echo "• Install 'fzf' for enhanced session selection"
    echo "• Use development template for coding projects"
    echo "• Configure settings in the Configuration menu"
    echo "• Sessions persist until manually deleted or system reboot"
    read -p "Press Enter to continue..."
}

# Enhanced rename and delete functions (keeping your original logic but with better UI)
rename_session() {
    local sessions=($(tmux list-sessions -F "#{session_name}" 2>/dev/null))
    if [ ${#sessions[@]} -eq 0 ]; then
        echo -e "${YELLOW}No sessions available to rename.${NC}"
        read -p "Press Enter to continue..."
        return
    fi

    local old_name
    if command -v fzf &> /dev/null; then
        old_name=$(printf "%s\n" "${sessions[@]}" | fzf --prompt="Select session to rename: ")
        [ -z "$old_name" ] && echo -e "${YELLOW}No session selected.${NC}" && return
    else
        echo -e "${BLUE}Select session to rename:${NC}"
        sessions+=("Back")
        select session in "${sessions[@]}"; do
            if [ "$session" == "Back" ]; then
                return
            elif [ -n "$session" ]; then
                old_name="$session"
                break
            else
                echo -e "${RED}Invalid choice. Try again.${NC}"
            fi
        done
    fi

    if [ -n "$old_name" ]; then
        read -p "Enter new name for session '$old_name': " new_name
        if [ -n "$new_name" ]; then
            if tmux rename-session -t "$old_name" "$new_name" 2>/dev/null; then
                echo -e "${GREEN}Session renamed from '$old_name' to '$new_name'.${NC}"
            else
                echo -e "${RED}Failed to rename session. Name might already exist.${NC}"
            fi
        else
            echo -e "${RED}New name cannot be empty.${NC}"
        fi
        read -p "Press Enter to continue..."
    fi
}

delete_session() {
    local sessions=($(tmux list-sessions -F "#{session_name}" 2>/dev/null))
    if [ ${#sessions[@]} -eq 0 ]; then
        echo -e "${YELLOW}No sessions available to delete.${NC}"
        read -p "Press Enter to continue..."
        return
    fi

    local to_delete
    if command -v fzf &> /dev/null; then
        to_delete=$(printf "%s\n" "${sessions[@]}" | fzf --prompt="Select session to delete: ")
        [ -z "$to_delete" ] && echo -e "${YELLOW}No session selected.${NC}" && return
    else
        echo -e "${BLUE}Select session to delete:${NC}"
        sessions+=("Back")
        select session in "${sessions[@]}"; do
            if [ "$session" == "Back" ]; then
                return
            elif [ -n "$session" ]; then
                to_delete="$session"
                break
            else
                echo -e "${RED}Invalid choice. Try again.${NC}"
            fi
        done
    fi

    if [ -n "$to_delete" ]; then
        echo -e "${BLUE}Session info:${NC} $(get_session_info "$to_delete")"
        read -p "Are you sure you want to delete session '$to_delete'? [y/N]: " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            tmux kill-session -t "$to_delete"
            echo -e "${GREEN}Session '$to_delete' deleted.${NC}"
        else
            echo -e "${YELLOW}Deletion cancelled.${NC}"
        fi
        read -p "Press Enter to continue..."
    fi
}

# Initialize
check_dependencies
load_config

# Main loop
while true; do
    show_menu
    read -r choice
    case "$choice" in
        1) list_and_attach ;;
        2) create_session ;;
        3) rename_session ;;
        4) delete_session ;;
        5) session_management ;;
        6) configuration_menu ;;
        7) show_help ;;
        8) echo -e "${GREEN}Goodbye!${NC}"; exit 0 ;;
        *) echo -e "${RED}Invalid option. Please choose 1-8.${NC}"; sleep 1 ;;
    esac
done
