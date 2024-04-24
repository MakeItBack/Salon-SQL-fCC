#!/bin/bash
PSQL="psql --username=freecodecamp --dbname=salon --tuples-only -c"

echo "
   ()))))                                       ((((()
  ())) o(                                       )o ((()
  )(((   >                                     <   )))(
  ()) _~                                         ~_ (()
  |__(       ~~~~ Welcome to the Salon! ~~~~       )__|
"

SERVICES_MENU() {
  if [[ $1 ]]
  then
    echo -e "\n$1"
  fi

  # Get a list of services
  ALL_SERVICES=$($PSQL "SELECT service_id, name FROM services ORDER BY service_id")

  # Display menu
  echo "Here are some services we offer:"
  echo "$ALL_SERVICES" | while read SERVICE_ID BAR SERVICE_NAME
  do
    if [[ $SERVICE_ID == [0-9] ]]
      then
        # print out a numbered list of services available
        echo "$SERVICE_ID) $SERVICE_NAME"
    fi
  done

  # Ask for the user to choose a service. Save the input and save it to a variable
  echo -e "\nWhat service would you like?"
  read SERVICE_ID_SELECTED

  # Check the input is valid
  SELECTED_SERVICE=$($PSQL "SELECT service_id, name FROM services WHERE service_id=$SERVICE_ID_SELECTED")
  # echo -e "selected service \n$SELECTED_SERVICE"

  # no service returned
  if [[ -z $SELECTED_SERVICE ]]
    then
      SERVICES_MENU "Invalid selection - please try again!\n"
    else
      CUSTOMER_QUESTIONNAIRE $SERVICE_ID_SELECTED
  fi
}

CUSTOMER_QUESTIONNAIRE() {
  SERVICE_ID_SELECTED=$1
  echo -e "\nSure, let me grab some more details so I can make your booking..."

  echo -e "\nWhat's your phone number?"
  read CUSTOMER_PHONE

  # Check if they are an existing customer from phone number
  CUSTOMER_SEARCH_RESULT=$($PSQL "SELECT customer_id, name FROM customers WHERE phone='$CUSTOMER_PHONE'")

  if [[ -z $CUSTOMER_SEARCH_RESULT ]]
      then
        # Ask for a customer name
        echo -e "\nLooks like you're a new customer, let's add you to our database:\nWhat's your name?"
        read CUSTOMER_NAME
        # Add customer to customers table
        ADD_CUSTOMER_RESULT=$($PSQL "INSERT INTO customers(name, phone) VALUES('$CUSTOMER_NAME', '$CUSTOMER_PHONE')")
        # Get the new customer ID
        CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'")

      else
        # Get customer details form from search result
        IFS='|' read -r CUSTOMER_ID CUSTOMER_NAME <<< "$CUSTOMER_SEARCH_RESULT"

        echo -e "Hi $CUSTOMER_NAME, you are already in our database"
  fi

  # Ask for an appointment time
  echo -e "\nWhat time would you like to make your booking?"
  read SERVICE_TIME

  # echo -e "\nCustomer ID: $CUSTOMER_ID, Name: $CUSTOMER_NAME, Phone: $CUSTOMER_PHONE, Service: $SERVICE_ID_SELECTED, Time: $SERVICE_TIME"

  CREATE_APPOINTMENT $CUSTOMER_ID $SERVICE_ID_SELECTED $SERVICE_TIME $CUSTOMER_NAME
}

CREATE_APPOINTMENT(){
  CREATE_APPOINTMENT_RESULT=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES($1, $2, '$3')")
  if [[ $CREATE_APPOINTMENT_RESULT == "INSERT 0 1" ]]
    then
      echo -e "\nNew appointment created!"
      SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id='$2'")
      echo -e "I have put you down for a $SERVICE_NAME at $3, $4.\n"
    else
      echo -e "\nError, something went wrong"
    fi
}

SERVICES_MENU
