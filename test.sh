# Set the root password
pass1=$(dialog --no-cancel --passwordbox "Enter your root password" 10 60 3>&1 1>&2 2>&3 3>&1)
pass2=$(dialog --no-cancel --passwordbox "Enter your root password again. To be sure..." 10 60 3>&1 1>&2 2>&3 3>&1)

while [ $pass1 != $pass2 ]
do
    pass1=$(dialog --no-cancel --passwordbox "Passwords do not match.\n\nEnter root password again." 10 60 3>&1 1>&2 2>&3 3>&1)
    pass2=$(dialog --no-cancel --passwordbox "Retype root password." 10 60 3>&1 1>&2 2>&3 3>&1)
    unset pass2
done
cat <<EOF | passwd
$pass1
$pass2
$pass2
EOF
