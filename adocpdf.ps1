$book_arg=$args[0]
Write-Output $book_arg
$container = "quay.io/tmichett/adoc-html:latest"
$current_directory = (get-location).path
Write-Output $current_directory
Invoke-Expression "docker run -it --name adochtml --rm -v $current_directory`:/tmp/ADOC_Work $container  $book_arg"
