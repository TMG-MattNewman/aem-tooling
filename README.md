# Simple usage:

on the command line run:

```
chmod +x *.sh
```

this makes the scripts executable, so then it can be run from the same directory by just calling the script and passing it the path of the page you want to convert, e.g:

## Hub conversion
```
./hub-converter.sh gaming
```

the script defaults to pointing to training, but can be pointed to a different environment using the -e flag (or -l to switch it to localhost for testing), when passing additional arguments the script then requires you to use the -p flag for the path:

```
./hub-converter-script.sh -e http://aem-docker-qa3.aws-preprod.telegraph.co.uk:4502/ -p gaming
```

the path will prepend /content/telegraph for you, so you don't need that part

## Copying content
```
./hub-content-copy.sh -f gaming2/reviews -t gaming/reviews 
```

to do this for many pages, just loop over a list in a file:
```
while read line; do ./hub-content-copy.sh -d -f $line -t $line ; done < ./news.txt
```

## Creating a package:
```
./package.sh -p test -c -a -b -d
```

## Generating filters:
```
./generate-filters.sh gaming
```

again, for many, just iterate over a list and output them to another file (in this case ./filters.txt):

```
while read line; do ./generate-filters.sh $line ; done < ./news.txt > ./filters.txt
```
