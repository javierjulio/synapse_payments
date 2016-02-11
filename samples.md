## Initialization

```ruby
require 'synapse_payments'

client = SynapsePayments::Client.new(client_id: 'client_id', client_secret: 'client_secret')

# or configure with a block (note: sandbox_mode is true by default)

client = SynapsePayments::Client.new do |config|
  config.client_id = 'your_client_id'
  config.client_secret = 'your_client_id'
  config.sandbox_mode = false
end
```

### Institutions

#### Retrieve all supported banks for login

```ruby
response = client.institutions

response.size
# => 16

response[1][:bank_name]
# => "Bank of America"
```

### Subscriptions

Note: This is a feature only available for the Advanced or Premium plans.

```ruby
client.subscriptions.all
client.subscriptions.create(url: 'http://site.com/callback', scope: ['USERS|PATCH'])
client.subscriptions.find(id)
client.subscriptions.update(id, url: 'http://site.com/new_callback', is_active: false)
```

### Users

All actions below require and assume user authentication.

#### Retrieve all users (paginated)

```ruby
response = client.users.all
```

#### Create a user

```ruby
response = client.users.create(
  name: 'John Smith', 
  email: 'johnsmith@example.com', 
  phone: '123-456-7890',
  fingerprint: 'abc123' # optional but recommended
)

# or specify multiple names, logins, phones...

response = client.users.create(
  name: ['John Smith', 'Bill Smith'], 
  email: [
    { email: 'johnsmith@example.com' },
    { email: 'billsmith@example.com' }
  ],
  phone: ['123-456-7890','123-555-6677']
)
```

#### Retrieve a user

```ruby
response = client.users.find(id)
```

#### Authenticate as a user

```ruby
response = client.users.find(id)

user_client = client.users.authenticate_as(id: id, refresh_token: response[:refresh_token])

user_client.refresh_token 
# => "refresh-459..."

user_client.expires_in    
# => "7200"

user = user_client.user # returns user representation

user[:_id]
# => "93f1..."

user[:legal_names]
# => ["Javier Julio"]
```

#### Update a user

```ruby
user_client.update(legal_name: 'John Smith', remove_login: { email: 'test@test.com' })
```

#### Add a document

```ruby
response = user_client.add_document(
  birthdate: Date.parse('1970/3/14'),
  first_name: 'John',
  last_name: 'Doe',
  street: '1 Infinite Loop',
  postal_code: '95014',
  country_code: 'US',
  document_type: 'SSN',
  document_value: '2222'
)
```

#### Answer KBA questions

```ruby
response = user_client.answer_kba(
  question_set_id: "557520ad343463000300005a", 
  answers: [
  	{ question_id: 1, answer_id: 1 },
  	{ question_id: 2, answer_id: 1 },
  	{ question_id: 3, answer_id: 1 },
  	{ question_id: 4, answer_id: 1 },
  	{ question_id: 5, answer_id: 1 }
  ]
)
```

#### Attach photo ID or another file type

```ruby
file_contents = File.read('image.png')
encoded_file = "data:image/png;base64,#{Base64.encode64(file_contents).gsub(/\n/, '')}"

user_client.update(doc: { attachment: encoded_file })
```

#### Add a bank account

```ruby
response = user_client.add_bank_account(
  name: 'John Doe',
  account_number: '72347235423',
  routing_number: '051000017',
  category: 'PERSONAL',
  type: 'CHECKING'
)
```

#### Bank account login

The following could return a list of nodes (bank accounts) or MFA question.

```ruby
response = user_client.bank_login(
  bank_id: 'bofa', # from bank_code at https://synapsepay.com/api/v3/institutions/show
  username: 'username',
  password: 'password'
)
```

#### Verify MFA for bank account login

Note that this is an additional step for some banks, since not all support MFA.

```ruby
response = user_client.verify_mfa(
  access_token: '8MNcKv1blk...', # returned in previous bank_login call
  answer: 'your answer'
)
```

#### Send money 💸

```ruby
response = user_client.send_money(
  from: node_id, 
  to: to_node_id, 
  to_node_type: 'SYNAPSE-US', 
  amount: 24.00, 
  currency: 'USD', 
  ip_address: '192.168.0.1'
)
```

#### Nodes

TODO: add more detail

```ruby
user_client.nodes.all
user_client.nodes.create(data)
user_client.nodes.delete(id)
user_client.nodes.find(id)
```

#### Transactions

TODO: add more detail

```ruby
user_client.nodes(node_id).transactions.all
user_client.nodes(node_id).transactions.create(node_id:, node_type:, amount:, currency:, ip_address:)
user_client.nodes(node_id).transactions.delete(id)
user_client.nodes(node_id).transactions.find(id)
user_client.nodes(node_id).transactions.update(id, data)
```

#### Error Handling

TODO: add detail
