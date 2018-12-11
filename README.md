# Simple usage:

on the command line run:

```
chmod +x ./hub-converter.sh ./hub-backup.sh 
```

this makes the scripts executable, so then it can be run from the same directory by just calling the script and passing it the path of the page you want to convert, e.g:

```
./hub-converter.sh gaming
```

the script defaults to pointing to training, but can be pointed to a different environment using the -e flag (or -l to switch it to localhost for testing), when passing additional arguments the script then requires you to use the -p flag for the path:

```
./hub-template-conversion-script.sh -e http://aem-docker-qa3.aws-preprod.telegraph.co.uk:4502/ -p gaming
```

the path will prepend /content/telegraph for you, so you don't need that part
