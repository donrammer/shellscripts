#! /bin/sh

#######################################################################################################################################################
#                                                    CentOS 8 - Install and Configure CheckMK 2.0 Agent                                               #
#                                                               Author - Richard Fletcher                                                             #
#                                                          E-mail: richard@imperviousits.co.uk                                                        #
#                                                               Version 1.0 - 18/01/2022                                                              #
#######################################################################################################################################################

#######################################################################################################################################################
#                                                                  Installing Xinetd                                                                  #
#######################################################################################################################################################

echo -e "\e[1;34m Installing Xinetd, please wait.... \e[0m"

{
yum install xinetd -y
} &> /dev/null

echo -e "\e[1;32m Xinetd installed Successfully! \e[0m"

#######################################################################################################################################################
#                                                             Installing CheckMK 2.0 Agent                                                            #
#######################################################################################################################################################

echo -e "\e[1;34m Downloading and installing CheckMK 2.0 Agent, please wait.... \e[0m"

{
yum -y install ./check-mk-agent-2.0.0p9-dcbad23b395f68a9.noarch.rpm
} &> /dev/null

echo -e "\e[1;32m CheckMK Agent installed Successfully! \e[0m"

#######################################################################################################################################################
#                                                                   Enable Services                                                                   #
#######################################################################################################################################################

echo -e "\e[1;34m Enabling the Xinetd service at boot.... \e[0m"

{
chkconfig xinetd on
} &> /dev/null

echo -e "\e[1;32m Xinetd service enabled at boot \e[0m"

#######################################################################################################################################################
#                                                                 Open Firewall Ports                                                                 #
#######################################################################################################################################################

echo -e "\e[1;34m Opening the required firewall ports.... \e[0m"

{
firewall-cmd --permanent --add-port=6556/tcp
firewall-cmd --reload
} &> /dev/null

echo -e "\e[1;32m Firewall ports opened successfully! \e[0m"

echo -e "\e[1;42m Congratulations! Installation Complete! Please add this node to your CheckMK Instance.\e[0m"
read -p 'Press ENTER to finish and quit this installation'

#######################################################################################################################################################
#                                                                 End of Script                                                                       #
#######################################################################################################################################################