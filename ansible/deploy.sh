#!/usr/bin/env bash
set -ev

deploy_team() {
    export profile=$1
    export TEAM_NAME=$2
    export PASSWORD=${3}
    export EIP=$4

    aws cloudformation deploy --template-file cloudformation.json --stack-name ${TEAM_NAME} \
     --capabilities CAPABILITY_NAMED_IAM --region eu-west-3 --parameter-overrides SubnetId=subnet-0c43b290d1517ef86 \
      TeamName=${TEAM_NAME} TeamPassword=${PASSWORD} SSHKeyName=${TEAM_NAME} GameEngineSecurityGroup=sg-0ff0c048b1d2710f1 \
      BuildIPAllocationId=${EIP} --profile ${profile} VpcId=vpc-0b2c92024cf13f9d0

    sleep 40

    export NODE1_IP="$(aws ec2 describe-instances  \
      --filter Name=tag:team,Values=${TEAM_NAME} Name=instance-state-name,Values=running Name=tag:usage,Values=node1 \
       --query='Reservations[].Instances[].{ Instance: Tags[?Key==`Name`]|[0].Value, PrivateIP: PrivateIpAddress}' --profile ${profile} \
       | jq '.[0].PrivateIP' | sed 's/\"//g')"

    export BUILD_IP="$(aws ec2 describe-instances  \
      --filter Name=tag:team,Values=${TEAM_NAME} Name=instance-state-name,Values=running Name=tag:usage,Values=build \
       --query='Reservations[].Instances[].{ Instance: Tags[?Key==`Name`]|[0].Value, PublicIP: PublicIpAddress}' --profile ${profile} \
       | jq '.[0].PublicIP' | sed 's/\"//g')"

	eval `ssh-agent -s`
    ssh-add ~/.ssh/${TEAM_NAME}.pem

    ansible-playbook -i inventory/ec2.py -e 'ansible_python_interpreter=/usr/bin/python3' \
     --limit "tag_usage_build:&tag_team_${TEAM_NAME}" buildInstance.yml

    ansible-playbook -i inventory/ec2.py -e 'ansible_python_interpreter=/usr/bin/python3' \
     --limit "tag_usage_loadbalancer:&tag_team_${TEAM_NAME}" loadbalancer.yml

    ssh-keygen -f "/home/ubuntu/.ssh/known_hosts" -R ${BUILD_IP}
    ssh-keygen -F ${BUILD_IP} || ssh-keyscan ${BUILD_IP} >> ~/.ssh/known_hosts

    sleep 15
	echo "Init Git"
    # init GIT
    git_dir=/tmp/ugly-system-${TEAM_NAME}/
    cp -R /tmp/ugly-system/ ${git_dir}
    cd ${git_dir}
    sed -i "s/{{ node1_ip }}/${NODE1_IP}/g" ./deploy/hosts
    git add .
    git commit --amend --no-edit
	echo "Git Remote Add"
    git remote add ${TEAM_NAME} ubuntu@${BUILD_IP}:ugly-system.git
	echo "Git Remote Push"
    git push ${TEAM_NAME} master:master -f

    rm -rf ${git_dir}

    cd -
    ssh-add -D
}

teams=( akinez aneitov astriturn azuno carebos dakonus dragano estea kaiphus kinziri luuria niborus obade ogophus ophore piwei pucara strooter tesade thunides tivilles trioteru votis xenvion zatruna )

passwords=( !QE5tR44sT8nf9p8Q !54GM2R35dHSihtr6 !WkA4643mryRfJ3R9 !gZtN6fv8P36dJ82Q !ii8456Zir6DNkS3S !p67nXj5qe8NHG77E !PP85a4q5Cne4CH8x !fTQ72u6F6epuUU54 !Vp7439TtEnh25tVE !89PQ3qQu3L9i8Luf !2Q9j8UC9dhm2SSx4 !5rV35Y3fYkG45rPa !p97em94VU37GrLaJ !59w4Z7rXSfVm4T8e !JA9M7382yqnYt5Nw !5eavYd6C93L24AQd !5BP9SSugyza443A3 !Bt7GeE84i6GWkz96 !k45WRkrb7Bp2D23Q !gx7LAvXH58E76e9i !2E8DKm8sNnfN25k6 !N646PbxZST2n83wy !Qv4Z3e3XtT8d8k4F !5kV7d99AZb2it2BZ !Sn7t3Sm4B4v56NGm )


elasticIps=( eipalloc-0bc94ad2c6fe3aeaf eipalloc-0a38036c6c51505a5 eipalloc-098e20f462cdaeea9 eipalloc-035254981ce3994d4 eipalloc-0454f295ab8012b3b )

for i in $(seq 0 1 14)
do :
    deploy_team deploy1 ${teams[$i]} ${passwords[$i]} ${elasticIps[$i]}
done


for i in $(seq 15 1 24)
do :
     deploy_team deploy2 ${teams[$i]} ${passwords[$i]} ${elasticIps[$i]}
done


