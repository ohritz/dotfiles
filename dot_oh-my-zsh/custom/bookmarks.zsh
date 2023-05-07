if [ -d "$HOME/.bookmarks" ]; then
    export CDPATH=".:$HOME/.bookmarks:/"
    alias goto="cd -P"
fi

bookmark () {
    local defaultBookmarkName="@$(basename $PWD)"
    local bookmarkName="${1:-$defaultBookmarkName}"
    ln -s $PWD "$HOME/.bookmarks/$bookmarkName"
    echo "created bookmark named ${bookmarkName} for ${PWD}."
}
