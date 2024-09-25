


while [ true ]
do

	read -p "Please, enter a Xilinx SW version 2019.1, 2019.2 or 2020.1: " word
	echo "Your choice: $word"

	if [ "$word" == "2019.2" ]; then
			echo "Loading configuration for $word"
		# Mentor
			#export PATH=$PATH:~/tools/Mentor/questasim/bin
			#export QUESTA_HOME=~/tools/Mentor/questasim/
		# Mathworks
			#export PATH=$PATH:~/tools/Mathworks/bin
			#export PATH=$PATH:~/tools/Mathworks/bin/mex
		# Xilinx
			source ~/Tools/Xilinx/Vitis/2019.2/settings64.sh
			#source /opt/xilinx/xrt/setup.sh
			#source ~/Tools/Xilinx/Petalinux/2019.2/settings.sh
			break

	elif [ "$word" == "2019.1"  ]; then
			echo "Loading configuration for $word"
		# Mentor
			#export PATH=$PATH:~/tools/Mentor/HLVX.2.7/SDD_HOME/hyperlynx
			#export PATH=$PATH:~/tools/Mentor/questasim/bin
			#export QUESTA_HOME=/home/xilinx/tools/Mentor/questasim/
		# Mathworks
			#export PATH=$PATH:~/tools/Mathworks/R2018b/bin
			#export PATH=$PATH:~/tools/Mathworks/R2018b/bin/mex
		# Xilinx
			source ~/Tools/Xilinx/Vivado/2019.1/settings64.sh
			break

	elif [ "$word" == "2020.1"  ]; then
			echo "Loading configuration for $word"
		# Mentor
			#export PATH=$PATH:~/tools/Mentor/questasim/bin
			#export QUESTA_HOME=~/tools/Mentor/questasim/
		# Mathworks
			#export PATH=$PATH:~/tools/Mathworks/bin
			#export PATH=$PATH:~/tools/Mathworks/bin/mex
		# Xilinx
			source ~/tools/Xilinx/Vitis/2020.1/settings64.sh 
			#source /opt/xilinx/xrt/setup.sh
			source ~/Tools/Xilinx/Petalinux/2020.1/settings.sh
			break

	else
		    echo "Incorrect, try again!!!"
	fi 

done
