#! /bin/bash

#########################################################################################
#					Global Variables					#
#########################################################################################

FieldSep=":"
RecordSep="\n"

#########################################################################################
#					Table Functions					#
#########################################################################################

function CreateTable {
	echo -e "Enter Tablename: \c"
	read tableName
	if ! [[ "$tableName" =~ [[:punct:]] || "$tableName" =~ [[:digit:]] || "$tableName" =~ [[:space:]] || -z "$tableName" ]]; then

		if [ -f "LocalDBs"/$1/$tableName"_meta.db" ]; then
			echo "Table already exist"
			TableMenu
		else

			echo -e "Enter Number of Columns: \c"
			read ColNum
			if ! [ -z "$ColNum" ]; then

				FieldSep=":"
				RecordSep="\n"
				PK=""
				meta="Field"$FieldSep"Type"$FieldSep"Key"
				ColType=""

				for ((i = 1; i <= $ColNum; i++)); do
					echo -e "\n\nEnter Column #$i Name: \c"
					read ColName
					echo -e "\nEnter Column Type: "
					while true; do
						select choice in "int" "varchar"; do
							case $REPLY in
							1)
								ColType="int"
								break 2
								;;

							2)
								ColType="varchar"
								break 2
								;;

							*)
								echo "invalid choice"
								;;
							esac
						done
					done

					if [[ -z $PK || $PK == "0" ]]; then

						echo -e "\nIs it Primary Key?"

						while true; do
							echo -e " 1 : YES , 2 : No >> \c"
							read choice
							case $choice in
							1)
								PK="1"
								meta=$meta$RecordSep$ColName$FieldSep$ColType$FieldSep"1"
								break
								;;
							2)
								PK="0"
								meta=$meta$RecordSep$ColName$FieldSep$ColType$FieldSep"0"
								break
								;;
							*)
								echo "invalid choice"
								;;
							esac
						done

					else
						meta=$meta$RecordSep$ColName$FieldSep$ColType$FieldSep"0"
					fi

				done
			else
				echo -e "NO Col Number Entered \n"
			fi
			echo -e "\n Printing data!"
			touch "LocalDBs"/$1/$tableName"_meta.db"
			touch "LocalDBs"/$1/$tableName".db"
			echo -e $meta >>"LocalDBs"/$1/$tableName"_meta.db"
		fi
	else
		echo -e "Enter a valid Table Name: \n"
	fi

	TableMenu
}

function DropTable {
	echo -e "Enter Table Name To Be Deleted: \c"
	read tableName
	if ! [ -z $tableName ]; then
		if [ -f "LocalDBs"/$1/$tableName"_meta.db" ]; then
			rm -i "LocalDBs"/$1/$tableName"_meta.db"
			rm -i "LocalDBs"/$1/$tableName".db"
		else
			echo "Table doesn't exist"

		fi
	else
		echo "No Table Name Entered"
		TableMenu
	fi

}

function InsertIntoTable {

	((numberOfChoices = $(ls LocalDBs/$1 | grep -c '._meta.db$') + 1))

	select choice in $(ls LocalDBs/$1 | grep '._meta.db$' | cut -d "_" -f1) "New" "Exit"; do

		if [[ $choice != "Exit" ]] && [[ $choice != "New" ]] && (($REPLY <= $numberOfChoices)); then
			TB_Name=$choice
			echo -e $TB_Name "selected succesfully!\n"
			break
		elif [[ $choice == "New" ]]; then
			CreateTable $1
			TB_Name=$tableName
			break
		elif [[ $choice == "Exit" ]]; then
			break
		else
			echo -e "\nInvalid Choice!\n Choose A Valid One!\n"
		fi
	done

	ColNum=$(awk 'END{print NR-1}' "LocalDBs"/$1/$TB_Name"_meta.db")
	NumberOfRecords=$(awk 'END{print NR}' "LocalDBs"/$1/$TB_Name".db")

	for ((i = 1; i <= ColNum; i++)); do

		ColName=$(awk 'BEGIN{FS=":"}{if(NR==(('$i' + 1))) print $1}' "LocalDBs"/$1/$TB_Name"_meta.db")
		ColType=$(awk 'BEGIN{FS=":"}{if(NR==(('$i'+ 1))) print $2}' "LocalDBs"/$1/$TB_Name"_meta.db")
		ColPK=$(awk 'BEGIN{FS=":"}{if(NR==(('$i'+ 1))) print $3}' "LocalDBs"/$1/$TB_Name"_meta.db")

		echo -e "Please Enter Coloumn Value: \n"
		echo -e "$ColName ( $ColType ) >> \c "
		read ColValue
		echo -e "\n"

		if [[ $ColType == "int" ]]; then
			while ! [[ $ColValue =~ ^[0-9]*$ ]]; do
				echo -e "Invalid Data Type!\nPlease Enter an Integer!\n"
				echo -e ">> \c"
				read ColValue
			done
		fi

		if [[ $ColPK == "1" ]] && (($NumberOfRecords > 0)); then
			while true; do
				if [[ $ColValue =~ ^[$(awk 'BEGIN{FS=":"; ORS=" "}{print $'$i'}' "LocalDBs"/$1/$TB_Name".db")]$ ]]; then
					echo -e "Value Already Exists!\nPlease Enter A Unique Value!\n"
					echo -e ">> \c"
					read ColValue
				else
					break
				fi

			done
		fi

		if [[ $i == $ColNum ]]; then
			record=$record$ColValue$RecordSep
		else
			record=$record$ColValue$FieldSep
		fi
	done
	echo -e "$record\c" >>"LocalDBs"/$1/$TB_Name".db"

	if [[ $? == 0 ]]; then
		echo "Row Inserted Succesfully!"
	else
		echo "Error Inserting Data Into Table $TB_Name"
	fi
	row=""
	TableMenu
}

function ShowTables {

	ls LocalDBs/$1 | grep '._meta.db$' | cut -d "_" -f1

}

function DeleteFromTable {

	((numberOfChoices = $(ls LocalDBs/$1 | grep -c '._meta.db$') + 1))

	while true; do
		echo -e "\nChoose Table \n"
		select TB_Name in $(ls LocalDBs/$1 | grep '._meta.db$' | cut -d "_" -f1) "Exit"; do

			if [[ $TB_Name != "Exit" ]] && (($REPLY <= $numberOfChoices)); then
				break 2
			elif [[ $TB_Name == "Exit" ]]; then
				break 2
			else
				echo -e "\nInvalid Choice!\n Choose A Valid One!\n"
			fi
		done
	done

	ColNum=$(awk 'END{print NR-1}' "LocalDBs"/$1/$TB_Name"_meta.db")

	while true; do
		echo -e "Choose Condition Coloumn \n"
		select Col_Name in $(awk '{if (NR > 1) print $0}' "LocalDBs"/$1/$TB_Name"_meta.db" | cut -d "$FieldSep" -f1) "Exit"; do

			if [[ $Col_Name != "Exit" ]] && (($REPLY <= $ColNum)); then
				echo $Col_Name
				break 2
			elif [[ $Col_Name == "Exit" ]]; then
				break 2
			else
				echo -e "\nInvalid Choice!\n Choose A Valid One!\n"
			fi
		done
	done

	((fieldNum = $(awk 'BEGIN{FS="'$FieldSep'"}{for(i=1;i<=NF;i++){if($i=="'$Col_Name'"){ print NR}}}' "LocalDBs"/$1/$TB_Name"_meta.db") - 1))

	echo -e "Enter Condition Value >> \c"
	read ConditionValue
	################################################

	ColType=$(awk 'BEGIN{FS=":"}{if(NR==(('$condition_fieldNum'+ 1))) print $2}' "LocalDBs"/$1/$TB_Name"_meta.db")
	#ColPK=$(awk 'BEGIN{FS=":"}{if(NR==(('$condition_fieldNum'+ 1))) print $3}' "LocalDBs"/$1/$TB_Name"_meta.db")

	echo -e "\nSupported Operators: \n"

	if [[ $ColType == "varchar" ]]; then
		echo -e "1: ==\t2: !=\t3: Go Back!\n"
		echo -e "\nSelect OPERATOR: \c"
		read opChoice

		case $opChoice in
		1)
			op="=="
			;;
		2)
			op="!="
			;;
		3)
			SelectFromTable
			;;
		*)
			echo -e "Invalid Operator\n"
			;;
		esac

	else
		echo -e "1: ==\t2: !=\t3: >\t4: <\t5: >=\t6: <=\t7: Go Back!\n"
		echo -e "\nSelect OPERATOR: \c"
		read opChoice

		case $opChoice in
		1)
			op="=="
			;;
		2)
			op="!="
			;;
		3)
			op=">"
			;;
		4)
			op="<"
			;;
		5)
			op=">="
			;;
		6)
			op="<="
			;;
		7)
			SelectFromTable
			;;
		*)

			echo -e "Invalid Operator\n"
			;;
		esac

	fi

	oldValue=$(awk 'BEGIN{FS="'$FieldSep'"}{if($'$fieldNum''$op'"'$ConditionValue'") print NR}' "LocalDBs"/$1/$TB_Name".db")

	#######################################################3
	#oldValue=$(awk 'BEGIN{FS="'$FieldSep'"}{if($'$fieldNum'=="'$ConditionValue'") print NR}' "LocalDBs"/$1/$TB_Name".db")

	if [[ -z $oldValue ]]; then
		echo -e "value not found!\n"

	else
		sed -i ''$oldValue'd' "LocalDBs"/$1/$TB_Name".db"
		if [[ $? == 0 ]]; then
			echo -e "Record Deleted Succesfully!"
		else
			echo "Failed!"
		fi
	fi

}

function UpdateTable {

	((numberOfChoices = $(ls LocalDBs/$1 | grep -c '._meta.db$') + 1))

	select TB_Name in $(ls LocalDBs/$1 | grep '.meta.db$' | cut -d "_" -f1) "Exit"; do

		if [[ $TB_Name != "Exit" ]] && (($REPLY <= $numberOfChoices)); then
			echo $TB_Name
			break
		elif [[ $TB_Name == "Exit" ]]; then
			break
		else
			echo -e "\nInvalid Choice!\n Choose A Valid One!\n"
		fi
	done
	ColNum=$(awk 'END{print NR-1}' "LocalDBs"/$1/$TB_Name"_meta.db")
	NumberOfRecords=$(awk 'END{print NR}' "LocalDBs"/$1/$TB_Name".db")
	ColNum=$(awk 'END{print NR-1}' "LocalDBs"/$1/$TB_Name"_meta.db")

	## Changing Coloumn

	while true; do
		echo -e "Please Select Coloumn Value To be Updated: \n"
		select Col_Name in $(awk '{if (NR > 1) print $0}' "LocalDBs"/$1/$TB_Name"_meta.db" | cut -d "$FieldSep" -f1) "Exit"; do

			if [[ $Col_Name != "Exit" ]] && (($REPLY <= $ColNum)); then
				echo $Col_Name
				break 2
			elif [[ $Col_Name == "Exit" ]]; then
				break 2
			else
				echo -e "\nInvalid Choice!\n Choose A Valid One!\n"
			fi
		done
	done

	((changing_fieldNum = $(awk 'BEGIN{FS="'$FieldSep'"}{for(i=1;i<=NF;i++){if($i=="'$Col_Name'"){ print NR}}}' "LocalDBs"/$1/$TB_Name"_meta.db") - 1))

	echo -e "Enter New Value >> \c"
	read newValue

	### Condition ###
	#Chosing Condition
	while true; do
		echo -e "Choose Condition Coloumn \n"
		select Col_Name in $(awk '{if (NR > 1) print $0}' "LocalDBs"/$1/$TB_Name"_meta.db" | cut -d "$FieldSep" -f1) "Exit"; do

			if [[ $Col_Name != "Exit" ]] && (($REPLY <= $ColNum)); then
				echo $Col_Name
				break 2
			elif [[ $Col_Name == "Exit" ]]; then
				break 2
			else
				echo -e "\nInvalid Choice!\n Choose A Valid One!\n"
			fi
		done
	done

	#Getting Condition Coloumn Field Number and Reading Condition Value

	((condition_fieldNum = $(awk 'BEGIN{FS="'$FieldSep'"}{for(i=1;i<=NF;i++){if($i=="'$Col_Name'"){ print NR}}}' "LocalDBs"/$1/$TB_Name"_meta.db") - 1))
	echo -e "Enter Condition Value >> \c"
	read ConditionValue
	####################
	touch "LocalDBs"/$1/$TB_Name"_temp.db"
	#ColName=$(awk 'BEGIN{FS=":"}{if(NR==(('$condition_fieldNum'+1))) print $1}' "LocalDBs"/$1/$TB_Name"_meta.db")
	ColType=$(awk 'BEGIN{FS=":"}{if(NR==(('$condition_fieldNum'+ 1))) print $2}' "LocalDBs"/$1/$TB_Name"_meta.db")
	#ColPK=$(awk 'BEGIN{FS=":"}{if(NR==(('$condition_fieldNum'+ 1))) print $3}' "LocalDBs"/$1/$TB_Name"_meta.db")

	echo -e "\nSupported Operators: \n"

	if [[ $ColType == "varchar" ]]; then
		echo -e "1: ==\t2: !=\t3: Go Back!\n"
		echo -e "\nSelect OPERATOR: \c"
		read opChoice

		case $opChoice in
		1)
			op="=="
			;;
		2)
			op="!="
			;;
		3)
			SelectFromTable
			;;
		*)
			echo -e "Invalid Operator\n"
			;;
		esac

	else
		echo -e "1: ==\t2: !=\t3: >\t4: <\t5: >=\t6: <=\t7: Go Back!\n"
		echo -e "\nSelect OPERATOR: \c"
		read opChoice

		case $opChoice in
		1)
			op="=="
			;;
		2)
			op="!="
			;;
		3)
			op=">"
			;;
		4)
			op="<"
			;;
		5)
			op=">="
			;;
		6)
			op="<="
			;;
		7)

			SelectFromTable
			;;
		*)

			echo -e "Invalid Operator\n"
			;;
		esac

	fi

	awk 'BEGIN{FS="'$FieldSep'"; ORS="\n";}{for(i=1;i<=NF;i++){if($'$condition_fieldNum''$op'"'$ConditionValue'"){gsub($'$changing_fieldNum',"'$newValue'");}} print $0}' "LocalDBs"/$1/$TB_Name".db" >"LocalDBs"/$1/$TB_Name"_temp.db"

	# Updating Value in Table

	cat "LocalDBs"/$1/$TB_Name"_temp.db" >"LocalDBs"/$1/$TB_Name".db"

	if [[ $? == 0 ]]; then
		echo -e "\nUpdated Succesfully!"
	else
		echo -e "\nUpdate Failed!"
	fi

}

function SelectFromTable {

	((numberOfChoices = $(ls LocalDBs/$1 | grep -c '._meta.db$') + 1))

	select TB_Name in $(ls LocalDBs/$1 | grep '.meta.db$' | cut -d "_" -f1) "Exit"; do

		if [[ $TB_Name != "Exit" ]] && (($REPLY <= $numberOfChoices)); then
			echo $TB_Name
			break
		elif [[ $TB_Name == "Exit" ]]; then
			break
		else
			echo -e "\nInvalid Choice!\n Choose A Valid One!\n"
		fi
	done

	select choice in "Query With Where Condition" "Query Without Where Condition" "Exit"; do
		case $REPLY in
		1)
			echo -e "1: Select All\t2: Select Coloumn\n>>\c"
			read mini
			case $mini in
			1)
				SelectAll_withCondition $1 $TB_Name
				cat "LocalDBs"/$1/"select_temp.db"

				break
				;;
			2)
				SelectCol_withCondition $1 $TB_Name
				cat "LocalDBs"/$1/"select_temp.db" | cut -d":" -f"$ViewingColoumn"
				break
				;;
			*)
				echo -e "Invalid Choice \c"
				break
				;;
			esac
			break
			;;
		2)
			echo -e "1: Select All\t2: Select Coloumn\n>>\c"
			read mini
			case $mini in
			1)
				SelectAllTable $1 $TB_Name
				break
				;;
			2)
				SelectCol $1 $TB_Name
				break
				;;
			*)
				echo -e "Invalid Choice \c"
				break
				;;
			esac
			break
			;;
		3)
			TableMenu
			break
			;;
		*)
			echo -e "Invalid Choice \c"
			;;
		esac
	done

}
function SelectAllTable {

	cat "LocalDBs"/$1/$2".db" | column -t -s ':'

}
function SelectCol {

	ColNum=$(awk 'END{print NR-1}' "LocalDBs"/$1/$2"_meta.db")

	## Changing Coloumn

	while true; do
		echo -e "Please Select Coloumn Value To be Updated: \n"
		select Col_Name in $(awk '{if (NR > 1) print $0}' "LocalDBs"/$1/$2"_meta.db" | cut -d "$FieldSep" -f1) "Exit"; do

			if [[ $Col_Name != "Exit" ]] && (($REPLY <= $ColNum)); then
				echo $Col_Name
				break 2
			elif [[ $Col_Name == "Exit" ]]; then
				break 2
			else
				echo -e "\nInvalid Choice!\n Choose A Valid One!\n"
			fi
		done
	done

	((FieldNum = $(awk 'BEGIN{FS="'$FieldSep'"}{for(i=1;i<=NF;i++){if($i=="'$Col_Name'"){ print NR}}}' "LocalDBs"/$1/$2"_meta.db") - 1))

	cat "LocalDBs"/$1/$2".db" | cut -d":" -f"$FieldNum" | column -t

}

function SelectCol_withCondition {
	echo -e "SelectCol_withCondition\n"

	ColNum=$(awk 'END{print NR-1}' "LocalDBs"/$1/$2"_meta.db")

	## Changing Coloumn

	while true; do
		echo -e "In While!\n"
		echo -e "Please Select Coloumn To View: \n"
		select Col_Name in $(awk '{if (NR > 1) print $0}' "LocalDBs"/$1/$2"_meta.db" | cut -d "$FieldSep" -f1) "Exit"; do

			if [[ $Col_Name != "Exit" ]] && (($REPLY <= $ColNum)); then
				echo $Col_Name
				break 2
			elif [[ $Col_Name == "Exit" ]]; then
				break 2
			else
				echo -e "\nInvalid Choice!\n Choose A Valid One!\n"
			fi
		done
	done

	((ViewingColoumn = $(awk 'BEGIN{FS="'$FieldSep'"}{for(i=1;i<=NF;i++){if($i=="'$Col_Name'"){ print NR}}}' "LocalDBs"/$1/$2"_meta.db") - 1))
	echo $ViewingColoumn

	SelectAll_withCondition $1 $2
	#cat "LocalDBs"/$1/"select_temp.db" | cut -d":" -f"$ViewingColoumn"

}

function SelectAll_withCondition {
	echo -e "SelectAll_withCondition\n"

	ColNum=$(awk 'END{print NR-1}' "LocalDBs"/$1/$2"_meta.db")

	## Changing Coloumn

	while true; do
		echo -e "In While!\n"
		echo -e "Please Select Condition Coloumn \: \n"
		select Col_Name in $(awk '{if (NR > 1) print $0}' "LocalDBs"/$1/$2"_meta.db" | cut -d "$FieldSep" -f1) "Exit"; do

			if [[ $Col_Name != "Exit" ]] && (($REPLY <= $ColNum)); then
				echo $Col_Name
				break 2
			elif [[ $Col_Name == "Exit" ]]; then
				break 2
			else
				echo -e "\nInvalid Choice!\n Choose A Valid One!\n"
			fi
		done
	done

	((FieldNum = $(awk 'BEGIN{FS="'$FieldSep'"}{for(i=1;i<=NF;i++){if($i=="'$Col_Name'"){ print NR}}}' "LocalDBs"/$1/$2"_meta.db") - 1))
	echo $FieldNum

	echo -e "\nSupported Operators: [==, !=, >, <, >=, <=] \nSelect OPERATOR: \c"
	read op
	if [[ $op == "==" ]] || [[ $op == "!=" ]] || [[ $op == ">" ]] || [[ $op == "<" ]] || [[ $op == ">=" ]] || [[ $op == "<=" ]]; then
		echo -e "\nEnter required VALUE: \c"
		read val
		#awk 'BEGIN{FS=":"; ORS="\n"}{if ($'$FieldNum''$op''$val') print $'$FieldNum'}' "LocalDBs"/$1/$2"_meta.db"

		res=$(awk 'BEGIN{FS=":"; ORS="\n"}{if ($'$FieldNum''$op'"'$val'") print $0}' "LocalDBs"/$1/$2".db")
		if [[ $res == "" ]]; then
			echo "Value Not Found"
			echo "" >"LocalDBs"/$1/"select_temp.db"
			#selectCon
		else
			#awk 'BEGIN{FS="|"; ORS="\n"}{if ($'$FieldNum$op$val') print $'$FieldNum'}' "LocalDBs"/$1/$2"_meta.db" |  column -t -s '|'

			echo $res >"LocalDBs"/$1/"select_temp.db"
			#return $res
		fi
	else
		echo "Unsupported Operator\n"

	fi

}

#########################################################################################
#					Database Functions				#
#########################################################################################

function CreateDB {

	while true; do
		echo -e "Enter DB Name: \n"
		read DBName
		if ! [[ "$DBName" =~ [[:punct:]] || "$DBName" =~ [[:digit:]] || "$DBName" =~ [[:space:]] ]]; then
			if [ -d "LocalDBs"/$DBName ]; then
				echo "DB already exists"
			else
				mkdir "LocalDBs"/$DBName
				echo $DBName >>local_DBMS.dbms
				break

			fi

		else
			echo -e "Enter a valid DB Name \n"

		fi
	done
}

function SelectDB {

	echo -e "\nChoose A Database or Create A New One: \n"

	DB_Name=""

	select DB_Name in $(awk '{print}' local_DBMS.dbms) "New" "Exit"; do

		if [[ $DB_Name != "Exit" && $DB_Name != "New" ]]; then
			echo -e "Connected To $DB_Name\n"
			break
		elif [[ $DB_Name == "New" ]]; then
			clear
			echo "Enter DB  Name"
			read DB_Name
			CreateDB $DB_Name
			break
		elif [[ $DB_Name == "Exit" ]]; then
			break
		else
			echo -e "Invalid Choice!\n Choose A Valid One!\n"
		fi
	done

	export DB_Name
	TableMenu
}

function RenameDB {

	echo -e "\nChoose A Database: \n"

	DB_Name=""

	select DB_Name in $(awk '{print}' local_DBMS.dbms) "Exit"; do

		if [[ $DB_Name != "Exit" ]]; then
			echo -e "Enter New Name >> \c"
			read newName
			if ! [[ "$newName" =~ [[:punct:]] || "$newName" =~ [[:digit:]] || "$newName" =~ [[:digit:]] ]]; then
				mv LocalDBs/$DB_Name LocalDBs/$newName
				sed -i "s/$DB_Name/$newName/" "local_DBMS.dbms"
				break
			else
				echo -e "Enter a Valid DB Name \n"
			fi
		elif [[ $DB_Name == "Exit" ]]; then
			break
		else
			echo -e "Invalid Choice!\n Choose A Valid One!\n"
		fi
	done

}

function DropDB {
	echo -e "Enter DB Name To be Deleted: \c"
	read dbName
	if [ -d "LocalDBs"/$dbName ]; then
		rm -r "LocalDBs"/$dbName
		sed -i "/$dbName/d" "local_DBMS.dbms"
	else
		echo "DB doesn't exist"
	fi
}

function ShowDBs {
	echo -e "\nLocal Databases: \n"
	awk '{print NR "-",$0}' local_DBMS.dbms
	echo -e "\n"

}
