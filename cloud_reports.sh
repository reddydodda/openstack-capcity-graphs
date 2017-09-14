#!/bin/bash
#This Script will Genrate and email reports to Mark's Team

echo "Genrating Reports: `date`"
#MySQL Username
username="capacity"

path=$(echo $PWD)
# path to venv 
venv_path="$path/venv"
password=$(cat $path/.mysql_password)
> $path/host_data.txt
> $path/vm_data.txt
> $path/project_data.txt

IFS=$'\n'

# Logic for pulling data for Hosts reports
for region in $(cat $path/mysql_hosts); do
            host_ip=$(echo $region | awk '{print $1}')
            region_name=$(echo $region | awk '{print $2}')
	        
            if [ "$region_name" != "PO-A" ]; then
              mysql_data=$(mysql -h $host_ip -u $username -p$password -N -e "select '$region_name' AS Region_Name,hypervisor_hostname,vcpus,   \
              memory_mb,local_gb,vcpus_used,memory_mb_used,local_gb_used,running_vms from nova.compute_nodes where deleted_at is NULL")
              printf "$mysql_data\n"
            elif [ "$region_name" = "region2" ]; then
            #po-a logic

            #PO-A API Calls
             source $venv_path/openstack/bin/activate
             source $path/openrc-region2
             unset http_proxy
             unset https_proxy
              for host in $(nova --insecure hypervisor-list | awk 'NR>2 {print $4}'); do
                host_data=$(nova --insecure hypervisor-show $host )
                vcpus=$( echo $host_data | awk '{for (I=1;I<=NF;I++) if ($I == "vcpus") {print $(I+2)};}')
                memory=$( echo $host_data | awk '{for (I=1;I<=NF;I++) if ($I == "memory_mb") {print $(I+2)};}')
                disk=$( echo $host_data | awk '{for (I=1;I<=NF;I++) if ($I == "disk") {print $(I+2)};}')
                local_gb=$( echo $host_data | awk '{for (I=1;I<=NF;I++) if ($I == "local_gb") {print $(I+2)};}')
                vcpus_used=$( echo $host_data | awk '{for (I=1;I<=NF;I++) if ($I == "vcpus_used") {print $(I+2)};}')
                memory_used=$( echo $host_data | awk '{for (I=1;I<=NF;I++) if ($I == "memory_mb_used") {print $(I+2)};}')
                local_gb_used=$( echo $host_data | awk '{for (I=1;I<=NF;I++) if ($I == "local_gb_used") {print $(I+2)};}')
                running_vms=$( echo $host_data | awk '{for (I=1;I<=NF;I++) if ($I == "running_vms") {print $(I+2)};}')

                printf "$region_name \t $host\t $vcpus\t $memory\t $disk $local_gb\t $vcpus_used\t $memory_used\t $local_gb_used\t $running_vms\n"

              done

            fi
#        printf "$mysql_data\n"
done >> $path/host_data.txt

for region in $(cat $path/mysql_hosts); do
                host_ip=$(echo $region | awk '{print $1}')
                region_name=$(echo $region | awk '{print $2}')
                region_type=$(echo $region | awk '{print $3}')
                if [ "$region_name" != "region2" ]; then
                #Non PO-A regions
                    if [ "$region_type" == "icehouse" ] ; then
                      mysql_data=$(mysql -h $host_ip -u $username -p$password -N -e "select '$region_name' AS Region_Name,uuid,hostname,host,vm_state,vcpus,memory_mb,   \
                      root_gb,ephemeral_gb,project_id from nova.instances where not (vm_state = 'deleted') ")
                    printf "$mysql_data\n" 
                    else
#                     mysql_data=$(mysql -h $host_ip -u $username -p$password -N -e "select '$region_name' AS Region_Name, uuid, hostname,host,vm_state,vcpus,memory_mb,root_gb,ephemeral_gb,project_id,'$project_name' AS Project_Name from nova.instances where project_id = '$project_id' ")
                      mysql_data=$(mysql -h $host_ip -u $username -p$password -N -e "select '$region_name' AS Region_Name,n.uuid,n.hostname,n.host,n.vm_state,n.vcpus,n.memory_mb,   \
                      n.root_gb,n.ephemeral_gb,n.project_id,k.name from nova.instances n INNER JOIN keystone.project k ON (n.project_id = k.id) where not (n.vm_state = 'deleted') ")
                    printf "$mysql_data\n"
                    fi

                elif [ "$region_name" = "region2" ]; then
                   #VM Data 
                   #PO-A API Calls
                   source $venv_path/openstack/bin/activate
                   source $path/openrc-region2
                   unset http_proxy
                   unset https_proxy

                    for vm in $(nova --insecure list --all-tenants | awk 'NR>2  {print $2}'); do
                      instance_data=$(nova --insecure show $vm )
                      instance_id=$( echo $instance_data | awk '{for (I=1;I<=NF;I++) if ($I == "id") {print $(I+2)};}')
                      instance_name=$( echo $instance_data | awk '{for (I=1;I<=NF;I++) if ($I == "name") {print $(I+2)};}')
                      instance_host=$( echo $instance_data | awk '{for (I=1;I<=NF;I++) if ($I == "OS-EXT-SRV-ATTR:hypervisor_hostname") {print $(I+2)};}')
                      instance_status=$( echo $instance_data | awk '{for (I=1;I<=NF;I++) if ($I == "status") {print $(I+2)};}')
                      instance_flavor=$( echo $instance_data | awk '{for (I=1;I<=NF;I++) if ($I == "flavor") {print $(I+2)};}' )
                      instance_project_id=$( echo $instance_data | awk '{for (I=1;I<=NF;I++) if ($I == "tenant_id") {print $(I+2)};}')
                    #Get Ram, vCPU and HDD deatils from flavor 
                      flavor_data=$(nova --insecure flavor-show $instance_flavor)
                      instance_ram=$( echo $flavor_data | awk '{for (I=1;I<=NF;I++) if ($I == "ram") {print $(I+2)};}')
                      instance_vcpus=$( echo $flavor_data | awk '{for (I=1;I<=NF;I++) if ($I == "vcpus") {print $(I+2)};}')
                      instance_disk=$( echo $flavor_data | awk '{for (I=1;I<=NF;I++) if ($I == "disk") {print $(I+2)};}')
                      instance_project_name=$(openstack --insecure project show $instance_project_id | awk '$2 == "name" {print $4}' )
                      instance_ephemeral_gb=0               
                    printf "$region_name\t $instance_id\t $instance_name\t $instance_host\t $instance_status\t $instance_vcpus\t  \
                    $instance_ram\t $instance_disk\t $instance_ephemeral_gb\t $instance_project_id\t $instance_project_name\n"

                    done
                fi
                #End of PO-A Data
                #printf "$mysql_data\n"
done >> $path/vm_data.txt 


               project_data=$(mysql -h $keystone -u $username -p$password -N -e "select id, name from keystone.project")
               printf "$project_data" > $path/project_data.txt
   
awk 'BEGIN{ OFS=","; print "Project_ID,Project_Name"}; NR > 0{print $1, $2;}' $path/project_data.txt > $path/project_report.csv

awk 'BEGIN{ OFS=","; print "Region Name,Hypervisor_Hostname,vcpus,memory_mb, local_gb, vcpus_used, memory_used, local_gb_used, running_vms"}; NR > 0{print $1, $2, $3, $4, $5, $6, $7, $8, $9;}' $path/host_data.txt > $path/host_report.csv

awk 'BEGIN{ OFS=","; print "Region Name, Instance ID, Name, Hypervisor_Hostname, Status, VCPUs, Memory_MB, Root_gb, Ephemeral_gb, project_id, Project_Name"}; NR > 0{print $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11;}' $path/vm_data.txt > $path/vm_report.csv

#Send MAil configuration 
echo "Sending Mail: `date`"
bash $path/mail_host.sh
bash $path/mail_vm.sh
bash $path/mail_region.sh
