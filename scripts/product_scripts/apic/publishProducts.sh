#!/bin/bash

export cluster_name=$1
export domain_name=$2
export namespace=$3
export apic_release_name=$4
export org=$5
export products_folder_path=$6
export user=$6
export password=$7

if [[ "$org" == "" ]]; then
  org=cts-demo
fi

#Creating cluster endpoint
apic_server=$apic_release_name-mgmt-api-manager-$namespace.apps.$cluster_name.$domain_name

echo "APIC Admin Endpoint :: ${apic_server}"

echo "Products Folder Path ${products_folder_path}" 
for FILE in ${products_folder_path}*product*; 
do 
   if [[ -f "$FILE" ]]; then
     echo  "Publishing $(basename "$FILE")"
     apic products:publish --server ${apic_server} --org ${org} --scope catalog --catalog sandbox $FILE
     var=$?
     if [[ var -eq 0 ]]; then
       mkdir -p published
       mv $FILE published/.
     fi
   else 
     echo "No Products to publish !!."
   fi
done

echo "Uploading APIs in draft state in API Manager"
for FILE in ${products_folder_path}*; 
do 
   if [[ -f "$FILE" ]]; then
     echo  "Publishing $(basename "$FILE")"
     apic draft-apis:create --server ${apic_server} --org ${org} $FILE
     var=$?
     if [[ var -eq 0 ]]; then
       mkdir -p draftapis
       mv $FILE draftapis/.
     fi
   else 
     echo "No APIs to upload !!."
   fi
done

