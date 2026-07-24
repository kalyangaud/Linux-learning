#!/bin/bash
echo "Enter the age :"
read age
if [ "$age" -ge 18 ]
then
     echo "You are eligible to vote."
else
     echo "You are not eligible"
fi

