# Day 5 - Linux Learning

## 1. find Command

The `find` command searches for files and directories.

### Find a file by name
```bash
find . -name "notes.txt"
```

### Find all text files
```bash
find . -name "*.txt"
```

### Find only files
```bash
find . -type f
```

### Find only directories
```bash
find . -type d
```

---

## 2. locate Command

`locate` searches a pre-built database, making it faster than `find`.

### Install plocate
```bash
sudo apt update
sudo apt install plocate
```

### Update the database
```bash
sudo updatedb
```

### Search examples
```bash
locate notes.txt
locate "*.sh"
```

---

## Difference Between find and locate

| find | locate |
|------|--------|
| Searches the filesystem | Searches a database |
| Slower | Faster |
| Always up to date | Needs updatedb |

---

## Notes

- `find` is available by default.
- `locate` may need `plocate` to be installed.
- If installation is interrupted:
```bash
sudo dpkg --configure -a
```
