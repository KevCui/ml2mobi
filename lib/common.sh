rename_foledr() {
    # $1: manga folder
    # $2: manga slug
    # $3: chapter num
    local n
    if [[ -z "${_RENAMED_MANGA_NAME:-}" ]]; then
        n="${2}_chapter${3}"
    else
        n="${_RENAMED_MANGA_NAME}_chapter${3}"
    fi
    mv "$1" "$n"
    echo "$n"
}

convert_img_to_mobi() {
    # $1: manga folder
    $_KCC $_KCC_OPTION "$1"
}

download_mangas() {
    # $1: manga number string
    # $2: chapter num string
    # $3: output folder
    if [[ "$2" == *","* ]]; then
        IFS=","
        read -ra ADDR <<< "$2"
        for e in "${ADDR[@]}"; do
            download_manga "$1" "$e" "$3"
        done
    else
        download_manga "$1" "$2" "$3"
    fi
}

download_manga() {
    # $1: manga slug
    # $2: chapter num
    # $3: output folder
    mkdir -p "$3"

    local i j s m f p
    if [[ "$2" == *"-"* ]]; then
        s=$(awk -F'-' '{print $1}' <<< "$2")
        m=$(awk -F'-' '{print $2}' <<< "$2")
    else
        s="$2"
        m="$2"
    fi

    p=""
    if [[ "$s" == *"_"* || "$m" == *"_"* ]]; then
        p="$(awk -F'_' '{print $1}' <<< "$s")_"
        s=$(awk -F'_' '{print $2}' <<< "$s")
        m=$(awk -F'_' '{print $2}' <<< "$m")
    fi

    i=1
    for j in $(seq "$s" .5 "$m"); do
        j=${j/.0/}
        while read -r l; do
            if [[ -n "$l" ]]; then
                echo "[INFO] Downloading $l..." >&2
                $_CURL -L -g -o "${3}/${i}.jpg" "$l" -H "Referer: $_HOST_URL"
                i=$((i+1))
            fi
        done <<< "$(fetch_img_list "$1" "${p}${j}")"
    done

    f="$(rename_foledr "$3" "$1" "$2")"

    if [[ -z ${_NO_MOBI:-} ]]; then
        convert_img_to_mobi "$f"
    fi

    if [[ -z ${_KEEP_OUTPUT:-} ]]; then
        rm -rf "$f"
    fi
}

sed_remove_space() {
    sed -E '/^[[:space:]]*$/d;s/^[[:space:]]+//;s/[[:space:]]+$//'
}
