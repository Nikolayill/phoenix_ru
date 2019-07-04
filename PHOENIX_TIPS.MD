#052-055
Что бы создать новый проект, выполнил:
`mix phoenix.new discuss`
При попытке выполнить:
`mix ecto.create`\
на сгененрированном проекте, получал сообщение:
```
== Compilation error in file lib/discuss/repo.ex ==
** (ArgumentError) missing :adapter option on use Ecto.Repo
    lib/ecto/repo/supervisor.ex:66: Ecto.Repo.Supervisor.compile_config/2
    lib/discuss/repo.ex:2: (module)
    (stdlib) erl_eval.erl:680: :erl_eval.do_apply/6
    (elixir) lib/kernel/parallel_compiler.ex:198: anonymous fn/4 in Kernel.Paral
lelCompiler.spawn_workers/6
```

Помог ответ 
https://stackoverflow.com/a/53057831
в топике
https://stackoverflow.com/questions/53045717/adapter-ecto-adapters-postgres-was-not-compiled

В `\discuss\mix.exs` были проапгрейжены зависимости:
```
	 {:ecto_sql, "~> 3.0"},
     {:phoenix_ecto, "~> 4.0"},
     {:postgrex, ">= 0.0.0"},
```

В `\discuss\lib\discuss\repo.ex` был добавлен параметр `adapter`:
```
defmodule Discuss.Repo do
  use Ecto.Repo, 
	otp_app: :discuss,
	adapter: Ecto.Adapters.Postgres
end
```

Затем выполнил:
```
mix deps.clean --all
mix do deps.get, compile
```
получил варнинги, но ошибок не было.
Выполнил `mix ecto.create` и получил вывод:
`The database for Discuss.Repo has already been created`
что вероятно говорит об успехе.

Запустил сервер командой `mix phoenix.server`. 
По адресу `http://localhost:4000` стала доступна чистая страничка.

Изменил html в шаблоне `\discuss\web\templates\page\index.html.eex`.
Изменения отобразились в браузере.

#056-057
Феникс поддерживает как приложения с рендернигом страниц на сервере, так и одностраничные.
В данном примере рассматривается рендеринг на сервере.

Папка `\discuss\web\templates\layout\` содержит макеты "layouts" для страниц,
шаблоны которых, располагаются в `\discuss\web\templates\page\`.
Файлы макетов/шаблонов имеют расширение `eex`.

Макет страниц приложения - `app.html.eex` в него имеет смысл добавлять элементы 
относящиеся к сквозной функциональности, например меню и подключение CSS стилей.

Для приложения должны использоваться стили "https://materializecss.com/".
В уроке прелоагается использовать CDN (но это не очень инстересно).
При попутке скачать стили и положить в `\discuss\web\static\vendor`, и 
затем добавить код `<link rel="stylesheet" href="<%= static_path(@conn, "/vendor/materialize/css/materialize.min.css") %>">` 
по аналогии с уже имеющимся в `app.html.eex` получаем сообщение в консоль браузера об 404 ошибке при обращении к `materialize.min.css`.
В консоль сервер выдает ошибку ` ** (Phoenix.Router.NoRouteError) no route found for GET /vendor/material....`.

Решение "в меру непонимания проблемы" в файле `\discuss\lib\discuss\endpoint.ex`: добавил `vendor` в код:
```
plug Plug.Static,
	at: "/", from: :discuss, gzip: false,
	only: ~w(css fonts images js vendor favicon.ico robots.txt)
```
CSS из папки vendor начали раздаваться...

#058-059
##Router-Controller
Модуль "роутер" определяет какой компонент приложения будет обрабатывать конкретный входящий запрос.
Код роутера расположен в `\discuss\web\router.ex`

Секция начинающаяся словом `scope` определяет скоуп для которого указываются правила обработки запросов.
Например `scope "/"` действует для запросов начинающихся с `/`.

Код `get "/", PageController, :index` указывает что при GET запросе к URL `/` 
нужно обратиться к функции `index` модуля `PageController` (`\discuss\web\controllers\page_controller.ex`). 
Эта функция и станет обработчиком запроса.

Для данного скоупа указан определенный пайплайн `pipe_through :browser`
-- помеченный символом `:browser`.
Сам пайплайн определен выше: `pipeline :browser`.

#060
##Views
Феникс неявно связывает модули представления (views) с файлами шаблонов (templates) в определенной папке.
Для связывания используются соглашения об именовании. Так шаблоны в папке `web/templates/page`
будут связаны с `web/views/page_view.ex`.
В модуль представления добавляется функция `render` которая "видит" шаблоны из связанной папки.
Например, если запусть феникс+iex:\
`iex -S mix phoenix.server` и выполнить `Discuss.PageView.render("index.html")`, в консоли отобразится
код отрендереной страницы.

#061-062
##Models
Модель представляет собой отображение записи из таблицы БД. 
Создание модели в БД начинается с генерации файла миграций (migration file) командой:\
`mix ecto.gen.migration add_topics`, где `add_topics` формальное название операции которая будет выполнена 
(добавление таблицы для хранения тем форума).
В консоль будет выдано сообщение вида `* creating priv/repo/migrations/20190612224957_add_topics.exs`
о том, что был сгененрирован скрипт `20190612224957_add_topics` по указанному пути.

В скрипте будет расположена пустая функция `change`, что бы создать таблицу в нее нужно добавить код:
```
  def change do
    create table(:topics) do
      add :title, :string
    end
  end
```
который указывает, что нужно создать таблицу `topics`
у которой должна быть текстовая колонка `title`.
Далее, что бы выполнить изменения в БД, нужно запустить миграцию командой:
`mix ecto.migrate`. Она выдаст в консоль отчет о выполнении
```
01:59:50.375 [info]  == Running 20190612224957 Discuss.Repo.Migrations.AddTopics.change/0 forward

01:59:50.375 [info]  create table topics

01:59:50.381 [info]  == Migrated 20190612224957 in 0.0s
```
И в базе данных появится таблица `topics` и последовательность `topics_id_seq`. 
Так же в БД появится таблица `schema_migrations` с метаинформацией о выполненных миграциях.

#063-064
Создание топика на форуме начинается с того что пользователь заходит на страницу формы: `/topics/new`.
Т.е. на сервер будет отправлен GET запрос по указанному URL. Что бы запрос был обработан
нужно добавить его в роутер `get "/topics/new", TopicController, :new`, 
так же нужно создать контроллер `TopicController`.

#065
##TopicController
По соглашению название модуля контроллера соответствует сущности в ед.числе, 
которую он обслуживает. Т.е. `topics` - `TopicController`.
В контроллере должна быть функция-обработчик `new` указанная в роутере (на пред. шаге).
Т.о. модуль будет выглядеть так:
```
defmodule Discuss.TopicController do
  def new() do

  end
end
```
Теперь, если запустить феникс, он не выдаст ошибки при старте.
Но при попытке открыть указанную страницу произойдет исключение:
```
Request: GET /topics/new
** (exit) an exception was raised:
    ** (UndefinedFunctionError) function Discuss.TopicController.init/1 is undefined or private    
```

#066
##import-alias-use
Феникс ожидает от контроллера некоторого определенного поведения. 
В элексире нет наследования как в ОО-языках, но есть ряд собственных решений
для переиспользования кода.
`import` - дает доступ из модуля к функциям другово модуля.\
`alias` - создает шорткат к другому модулю.\
`use` - позволяет "гибко" (?) связать модули.\

Например:
существует модуль `Math`
```
defmodule Math do
  def add(a,b), do: a+b
end
```
что бы в модуле `TopicController` использовать функцию `add`,
можно обратиться к ней через полное имя модуля:
```
defmodule TopicController do
  def new() do
	Math.add(1,2)
  end
end
```
 
если в модуле `TopicController` написать `import Math`, 
функция `add` станет доступна извне как `TopicController.add`:
```
defmodule TopicController do
  import Math
  
  def new() do
	add(1,2)
  end
end
```

если в модуле `TopicController` написать `alias Math`, 
функция `add` будет доступна только в самом `TopicController`:
```
defmodule TopicController do
  alias Math
  
  def new() do
	add(1,2)
  end
end
```

#067
##use
Для "наследования" общего поведения контроллера используется выражение 
`use Discuss.Web, :controller` (см. `web/controllers/page_controller.ex` стр.2).
`use` позволяет гибко настраивать импорты. 
В данном примере в выражении содержится ссылка на функцию `controller` 
в модуле `Discuss.Web`.

Модуль `Discuss.Web` (см.`web/web.ex`) содержит такой код:
```
  def controller do
    quote do
      use Phoenix.Controller

      alias Discuss.Repo
      import Ecto
      import Ecto.Query

      import Discuss.Router.Helpers
      import Discuss.Gettext
    end
  end
``` 
В нём указана целая группа импортов, которые и будут подключены к модулю контроллера
`use Discuss.Web, :controller`.
В модуле `Discuss.Web` есть такие функции для всех основных частей приложения
(model, view, router, controller, channel).
Если в проекте появится некоторая общая функциональность, то ее можно вынести
в отдельный модуль и добавить импорт в соответствующую функцию.
 
Например, новая функциональность помещена в модуль `Discuss.CustomHelpers`, тогда
что бы подключить её к каждому контроллеру нужно модифицировать код так:
```
  def controller do
    quote do
      use Phoenix.Controller

      alias Discuss.Repo
      import Ecto
      import Ecto.Query

      import Discuss.Router.Helpers
      import Discuss.Gettext
      import Discuss.CustomHelpers # <-- функции нужные в каждом контроллере 
    end
  end
```

PS: здесь используется метапрограммирование - блок `quote` (см. https://elixirschool.com/ru/lessons/advanced/metaprogramming/#quote).
По сути `use` встраивает блок содержащийся в `quote` в код модуля.

#068
## Параметры функции контроллера
Теперь при попытке запустить сервер возникает другая ошибка:
```
Request: GET /topics/new
** (exit) an exception was raised:
    ** (UndefinedFunctionError) function Discuss.TopicController.new/2 is undefined or private. Did you mean one of:

      * new/0
```
Строка `function Discuss.TopicController.new/2 is undefined or private.` указывает что в контроллере недоступна функция
`new` с ожидаемым количеством параметров (2).
В эликсире количество параметров указывается следом за именем функции, между именем и числом ставится слэш.

Можно добавить параметры по аналогии с `web/controllers/page_controller.ex` и попытаться вывести их значения на экран.
#### IO.puts, IO.inspect
 Функция `IO.puts` выводит строку на экран\
 Функция `IO.inspect` выводит значение структуры данных и её вложенных частей.\
 С помощью этих функций можно увидеть, что за значения передаются в контроллер. 
 
Текст ошибки при обращении к странице, снова поменяется:
```
Request: GET /topics/new
** (exit) an exception was raised:
    ** (RuntimeError) expected action/2 to return a Plug.Conn, all plugs must receive a connection (conn) and return a connection
```
И в консоли появятся значения параметров:\
`conn` содержит структуру `%Plug.Conn{ *** }` заполненную параметрами и заголовками HTTP запроса 
и некоторыми дополнительными значениями.\
`params` в данном случае будет пустой ассоциативный массив `%{}`, но если посторить запрос добавив параметр:
`http://localhost:4000/topics/new?test=1` то в массиве будет `%{"test" => "1"}`.

##Plug.Conn
`Plug.Conn` содержит входящий HTTP запрос, и в такой же структуре должен содержаться ответ. 
Эта структура используется на всех этапах обработки запроса в фениксе.  

#069-070
##model
Что бы реализовать форму для создания новой темы форума, нужна модель которая будет представлять данные в форме.
Модель `Discuss.Topic` будет размещена в `web/models/discuss/topic.ex`. 
Как упоминалось выше (см. "067") в модуль нужно добавить некоторые общие функции: `use Discuss.Web, :model`.

Модель должна содержать схему данных, которую будет использовать феникс.
```
  schema "topics" do
    field :title, :string
  end
```
Схема указывает фениксу, что данные для модели хранятся в таблице `topics` которая имеет текстовое поле `title`.

#071-073
##Валидация модели
####Changeset
В модуле `Discuss.Topic` можно определить функцию валидации.\
Для валидации данных модели используется модуль и структура `Ecto.Changeset` (см.https://elixirschool.com/en/lessons/ecto/changesets/)
Пустая структура имеет вид:
```
iex(6)> %Ecto.Changeset{}
 #Ecto.Changeset<action: nil, changes: %{}, errors: [], data: nil, valid?: false>
```
Что бы ее заполнить нужно воспользоваться функцией `Ecto.Changeset.cast/4`:
```
iex(8)> Ecto.Changeset.cast(%Discuss.Topic{title: "Test"}, %{"title" => "New title"}, [:title])
#Ecto.Changeset<
  action: nil,
  changes: %{title: "New title"},
  errors: [],
  data: #Discuss.Topic<>,
  valid?: true
>
```
Функция первым параметром принимает исходное значение валидируемой структуры, вторым параметром - измененное значение,
третьим параметром - набор отслеживаемых полей. Изменение других полей не будет обработано, - если в примере выше, 
изменить третий параметр на пустой список, то функция верент пустую структуру:
```
iex(9)> Ecto.Changeset.cast(%Discuss.Topic{title: "Test"}, %{"title" => "New title"}, [])
#Ecto.Changeset<action: nil, changes: %{}, errors: [], data: #Discuss.Topic<>,
 valid?: true>
```
####Функции-валидаторы (Ecto.Changeset.validate_required)
В `Ecto` существует набор предопределенных функций варидации. Для валидации `Discuss.Topic` 
в модуль нужно добавить функцию формирующую changeset и применяющую к нему валидатор:
```
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:title])
    |> validate_required([:title])
  end
```
здесь `validate_required` - один из валидаторов `Ecto` указывающий, что поле `title` обязательно должно быть заполнено.
Пример:
```
iex(14)> Ecto.Changeset.cast(%Discuss.Topic{title: ""}, %{"title" => "New topic"}, [:title]) |> Ecto.Changeset.validate_required([:title])
#Ecto.Changeset<
  action: nil,
  changes: %{title: "New topic"},
  errors: [],
  data: #Discuss.Topic<>,
  valid?: true
>
```
флаг `valid?: true` указывает, что после изменения запись валидна.
Если поменять второй параметр на `%{"title" => ""}` (поле `title` содержит пустую строку):
```
iex(15)> Ecto.Changeset.cast(%Discuss.Topic{title: ""}, %{"title" => ""}, [:title]) |> Ecto.Changeset.validate_required([:title])
#Ecto.Changeset<
  action: nil,
  changes: %{},
  errors: [title: {"can't be blank", [validation: :required]}],
  data: #Discuss.Topic<>,
  valid?: false
>
```
Валидатор выставит флаг `valid?: false` - запись не валидна, а в поле `errors`
будет указано сообщение и причина.

#####Значение аргумента функции по умолчанию
В приведенном выше примере функции `changeset` за вторым аргументом 
`params` следует двойной слэш `\\` и значение `%{}` - пустой асоц.массив:\
`def changeset(struct, params \\ %{}) do`\
Так в элексире обозначается значение аргумента по умолчанию. 

#074
##view + template 
Что бы создать представление для формы, нужно добавить модуль `TopicView` в каталог `views`.
В соответствии с соглашением файл будет называться: `web/views/topic_view.ex`.\
В этот модуль нужно добавить импорт функциональности представления: `use Discuss.Web, :view`.\
Так же нужно создать шаблон HTML формы.\
По соглашению, он должен располагаться в каталоге `web/templates/topic`.\
Сейчас в шаблоне можно указать тестовый код `<h1>New Test Form</h1>`, 
что бы предварительно проверить будет ли он рендериться.
В контроллере `TopicController`, функцию `new` нужно дополнить командой рендеринга шаблона:
```
  def new(conn, params) do
    changeset = Topic.changeset(%Topic{}, %{})
    
    render conn, "new.html"
  end
```
Теперь можно попробовать запустить сервер `mix phoenix.start`
и открыть `http://localhost:4000/topics/new` - 
на экране должен появиться текст который был внесен в шаблон.

#075
##template
Форму можно создать на основе ченьжсета используемой модели.\
Для этого нужно использовать встраиваемый в шаблон код. Например, если в шаблон добавить строчку:
```
<%= 1 + 1 %>
```
то код заключенный между `<%=` и `%>`, 
будет вычислен и результат вычисления отображен на странице.

Генерация кода формы происходит в функции `form_for`, 
генерация поля ввода в `text_input` и кнопки в `submit`.\
При рендере шаблона в него могут быть переданы некоторые значения (контекст), 
 к ним можно обратиться по имени начинающемся с символа `@`.\
Контекст - это ассоциативный массив который передается третьим 
параметром функции `render` в контроллере:
```
render conn, "new.html", changeset: changeset
```
Шаблон обращается к значениям по их ключам `@changeset`.\
Структура `conn` всегда передается в шаблон и доступна через `@conn`.
Теперь если открыть страницу формы, появится сообщение об ошибке:
```
Request: GET /topics/new
** (exit) an exception was raised:
    ** (ArgumentError) No helper clause for Discuss.Router.Helpers.topic_path/2 defined for action :create.
The following topic_path actions are defined under your router:

  * :new
```

#076
##REST-соглашения, обработчик POST запроса
Ошибка происходит т.к. феникс не находит ожидаемый обработчик запросов.
Феникс следует REST-соглашениям для доступа к ресурсам:

**цель** |**запрос**  | **функция контроллера**
-----:|:-------|:---------------------
получить страницу с формой | **GET** '/topic/new' | new
отправить форму | **POST** '/topics' | create
получить список всех тем | **GET** '/topics' | index
удалить тему с ID = 12 | **DELETE** '/topics/12' | delete
получить страницу с формой редактирования записи с ID = 12 | **GET** '/topics/12' | edit
отправить форму с изменениями в записи с ID = 12 | **PUT** '/topics/12' | update

Т.о. в роутере нужно определить новый путь: `post "/topics", TopicController, :create`.
Теперь при открытии страницы отображается форма с полем ввода и кнопкой.
Но при нажатии кнопки мы будем получать ошибку, т.к. сам обработчик в контроллере не определен.

Если определить в контроллере функцию `create`:
```
  def create(conn, params) do
    IO.inspect(params)
  end
```
И попытаться отправить заполненную форму, в консоль будет выведено значение в `params`:
```
%{
  "_csrf_token" => "CDELFDhzXCEGWwF5OgJoFAgTCScFAAAAFFbyz43dV8gKRlQLqYMwgw==",
  "_utf8" => "тЬУ",
  "topic" => %{"title" => "gfdgd"}
}
```
Видно, что данные введенные в поле попадают в параметр "topic", значением в котором является ассоциативный массив,
в котором каждому полю формы соответствует отдельный ключ.
####Ассоциативный массив
[Ассоциативный массив](https://elixirschool.com/ru/lessons/basics/collections/#%D0%B0%D1%81%D1%81%D0%BE%D1%86%D0%B8%D0%B0%D1%82%D0%B8%D0%B2%D0%BD%D1%8B%D0%B5-%D0%BC%D0%B0%D1%81%D1%81%D0%B8%D0%B2%D1%8B) это неупорядоченная коллекция пар ключ-значение, 
где ключем может являться любое значение, а не только атом как в ключевых списках.\
Что бы получить из него данные можно воспользоваться паттер матчингом:
`%{"topic" => topic} = params`\
тогда в переменную `topic` попадет значение по ключу `"topic"`, т.е. `%{"title" => "gfdgd"}`.\
Выражения паттерн матчинга может использоваться непосредственно вместо аргументов функции:
```
  def create(conn, %{"topic" => topic} = params) do
```
здесь `%{"topic" => topic} = params` означает - сопоставить второй аргумент с образцом и поместить
значение с ключем `"topic"` в переменную `"topic"`, 
а полное значение второго аргумента поместить в `params`. 
#077
####Router.Helpers
Команда (задача) `mix phoenix.routes` отображает в консоль пути определаенные в проекте.\
Например, если её выполнить для данного проекта, она должна вывести:
```
 page_path  GET   /            Discuss.PageController :index
topic_path  GET   /topics/new  Discuss.TopicController :new
topic_path  POST  /topics      Discuss.TopicController :create
```
в первой колонке имя [функции хелпера](https://hexdocs.pm/phoenix/routing.html#path-helpers)
генерируемой для конкретного контроллера, ассоциированного с ним URL и типа HTTP запроса.
Хелперы служат для абстрагирования от конкретных путей при указании URL. Например в шаблоне:
`web/templates/topic/new.html.eex` для указания пути отправки из формы: `<%= form_for @changeset, topic_path(@conn, :create), fn f -> %>`.
Здесь `topic_path(@conn, :create)` вернет `/topics`:
```
iex(1)> alias Discuss.Router.Helpers, as: Routes
Discuss.Router.Helpers
iex(2)> Routes.topic_path(%Plug.Conn{}, :new)
"/topics/new"
```
#078
##Repo
Для вставки записи в таблицу БД используется функция `Repo.insert/1` принимающая в к-ве аргумента
структуру("changeset") сгененрированную с помощью `Topic.changeset`. Т.о. минимально, 
функция контроллера `Discuss.TopicController.create` должна содержать:
```
	changeset = Topic.changeset(%Topic{}, topic)
	Repo.insert(changeset)
```
Так же следует добавить проверку результата. `Repo.insert` - функция возвращает кортеж первый элемент
которого атом `ok:` в случае успешного выполнения и `error:` в случае ошибки.
```
    case Repo.insert(changeset) do
      {:ok, post} -> IO.inspect(post)
      {:error, changeset} -> IO.inspect(changeset) #обработка ошибки
    end
```
Если теперь запустить сервере `mix phoenix.server`, открыть форму `http://localhost:4000/topics/new`,
заполнить название и нажать кнопку "Save Topic" - в таблицу будет выполнена вставка. После нажатия кнопки
будет отображена страница ошибки т.к. код из примера выше не возвращает HTTP ответ - структуру `Plug.Conn`.

В логе будут отображены данные формы:
```
[debug] Processing by Discuss.TopicController.create/2
  Parameters: %{"_csrf_token" => "JTwjUDcVPhI0WmpaFj42ERIxBgEHAAAAdDbaOpQfL/9nyNPdfpjvbA==", "_utf8" => "тЬУ", "topic" => %{"title" => "gfdgd"}}
```
затем сформированный SQL запрос и значение структуры:
```
%Discuss.Topic{
  __meta__: #Ecto.Schema.Metadata<:loaded, "topics">,
  id: 1,
  title: "JS frameworks"
}
```





