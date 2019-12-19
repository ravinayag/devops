### changing the filenames from UPPER  to lower
```
$ ls
FILE1 FILE2 File3
$ for a in `ls` ; do mv $a "${a,,}" ; done
$ ls 
file1 file2 file3
$
```

### Changing the filenames from lower to UPPER
```
$ ls 
file1 file2 file3 dir1 
$ for a in `ls` ; do mv $a "${a^^}" ; done
$ ls 
FILE1 FILE2 FILE3 DIR1
$
```
