import os
from datetime import datetime, date
from flask import Flask, render_template, redirect, url_for, flash, request
from flask_login import LoginManager, UserMixin, login_user, login_required, logout_user, current_user
from flask_sqlalchemy import SQLAlchemy
from werkzeug.security import generate_password_hash, check_password_hash

app = Flask(__name__)
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'change-this-in-production')
database_url = os.getenv('DATABASE_URL', 'sqlite:///maintenance.db')
if database_url.startswith('postgres://'):
    database_url = database_url.replace('postgres://', 'postgresql://', 1)
app.config['SQLALCHEMY_DATABASE_URI'] = database_url
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db = SQLAlchemy(app)
login_manager = LoginManager(app)
login_manager.login_view = 'login'
login_manager.login_message = 'Inicia sesión para continuar.'

class User(UserMixin, db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)
    role = db.Column(db.String(30), default='Tecnico', nullable=False)

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

class Equipment(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    code = db.Column(db.String(50), unique=True, nullable=False)
    name = db.Column(db.String(120), nullable=False)
    area = db.Column(db.String(120), nullable=False)
    manufacturer = db.Column(db.String(120))
    model = db.Column(db.String(120))
    serial_number = db.Column(db.String(120))
    status = db.Column(db.String(30), default='Activo', nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

class WorkOrder(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(180), nullable=False)
    description = db.Column(db.Text)
    priority = db.Column(db.String(20), default='Media', nullable=False)
    status = db.Column(db.String(30), default='Abierta', nullable=False)
    due_date = db.Column(db.Date)
    equipment_id = db.Column(db.Integer, db.ForeignKey('equipment.id'), nullable=False)
    assigned_to = db.Column(db.String(120))
    created_by = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    completed_at = db.Column(db.DateTime)
    equipment = db.relationship('Equipment', backref='work_orders')
    creator = db.relationship('User', backref='created_work_orders')

@login_manager.user_loader
def load_user(user_id):
    return db.session.get(User, int(user_id))

@app.route('/login', methods=['GET', 'POST'])
def login():
    if current_user.is_authenticated:
        return redirect(url_for('dashboard'))
    if request.method == 'POST':
        user = User.query.filter_by(username=request.form['username'].strip()).first()
        if user and user.check_password(request.form['password']):
            login_user(user)
            return redirect(url_for('dashboard'))
        flash('Usuario o contraseña incorrectos.', 'danger')
    return render_template('login.html')

@app.route('/logout')
@login_required
def logout():
    logout_user()
    return redirect(url_for('login'))

@app.route('/')
@login_required
def dashboard():
    today = date.today()
    stats = {
        'equipment': Equipment.query.count(),
        'open_orders': WorkOrder.query.filter(WorkOrder.status != 'Cerrada').count(),
        'overdue': WorkOrder.query.filter(WorkOrder.due_date < today, WorkOrder.status != 'Cerrada').count(),
        'closed': WorkOrder.query.filter_by(status='Cerrada').count()
    }
    recent_orders = WorkOrder.query.order_by(WorkOrder.created_at.desc()).limit(8).all()
    return render_template('dashboard.html', stats=stats, recent_orders=recent_orders, today=today)

@app.route('/equipos')
@login_required
def equipment_list():
    return render_template('equipment.html', equipment=Equipment.query.order_by(Equipment.code).all())

@app.route('/equipos/nuevo', methods=['GET', 'POST'])
@login_required
def equipment_new():
    if request.method == 'POST':
        code = request.form['code'].strip()
        if Equipment.query.filter_by(code=code).first():
            flash('El código del equipo ya existe.', 'danger')
            return render_template('equipment_form.html', item=None)
        item = Equipment(code=code, name=request.form['name'].strip(), area=request.form['area'].strip(),
                         manufacturer=request.form.get('manufacturer','').strip(), model=request.form.get('model','').strip(),
                         serial_number=request.form.get('serial_number','').strip(), status=request.form['status'])
        db.session.add(item); db.session.commit()
        flash('Equipo agregado.', 'success')
        return redirect(url_for('equipment_list'))
    return render_template('equipment_form.html', item=None)

@app.route('/equipos/<int:item_id>/editar', methods=['GET', 'POST'])
@login_required
def equipment_edit(item_id):
    item = db.get_or_404(Equipment, item_id)
    if request.method == 'POST':
        duplicate = Equipment.query.filter(Equipment.code == request.form['code'].strip(), Equipment.id != item.id).first()
        if duplicate:
            flash('El código del equipo ya existe.', 'danger')
            return render_template('equipment_form.html', item=item)
        for field in ['code','name','area','manufacturer','model','serial_number','status']:
            setattr(item, field, request.form.get(field, '').strip())
        db.session.commit(); flash('Equipo actualizado.', 'success')
        return redirect(url_for('equipment_list'))
    return render_template('equipment_form.html', item=item)

@app.route('/ordenes')
@login_required
def workorder_list():
    status = request.args.get('status')
    query = WorkOrder.query
    if status:
        query = query.filter_by(status=status)
    return render_template('workorders.html', orders=query.order_by(WorkOrder.created_at.desc()).all(), selected_status=status)

@app.route('/ordenes/nueva', methods=['GET', 'POST'])
@login_required
def workorder_new():
    equipment = Equipment.query.filter_by(status='Activo').order_by(Equipment.name).all()
    if request.method == 'POST':
        due = datetime.strptime(request.form['due_date'], '%Y-%m-%d').date() if request.form.get('due_date') else None
        order = WorkOrder(title=request.form['title'].strip(), description=request.form.get('description','').strip(),
                          priority=request.form['priority'], status='Abierta', due_date=due,
                          equipment_id=int(request.form['equipment_id']), assigned_to=request.form.get('assigned_to','').strip(),
                          created_by=current_user.id)
        db.session.add(order); db.session.commit(); flash('Orden de trabajo creada.', 'success')
        return redirect(url_for('workorder_list'))
    return render_template('workorder_form.html', order=None, equipment=equipment)

@app.route('/ordenes/<int:order_id>/editar', methods=['GET', 'POST'])
@login_required
def workorder_edit(order_id):
    order = db.get_or_404(WorkOrder, order_id)
    equipment = Equipment.query.order_by(Equipment.name).all()
    if request.method == 'POST':
        order.title = request.form['title'].strip()
        order.description = request.form.get('description','').strip()
        order.priority = request.form['priority']; order.status = request.form['status']
        order.equipment_id = int(request.form['equipment_id'])
        order.assigned_to = request.form.get('assigned_to','').strip()
        order.due_date = datetime.strptime(request.form['due_date'], '%Y-%m-%d').date() if request.form.get('due_date') else None
        order.completed_at = datetime.utcnow() if order.status == 'Cerrada' else None
        db.session.commit(); flash('Orden actualizada.', 'success')
        return redirect(url_for('workorder_list'))
    return render_template('workorder_form.html', order=order, equipment=equipment)

@app.cli.command('init-db')
def init_db():
    db.create_all()
    if not User.query.filter_by(username='admin').first():
        admin = User(username='admin', role='Administrador'); admin.set_password('Admin123!')
        db.session.add(admin); db.session.commit()
        print('Base creada. Usuario: admin / Contraseña: Admin123!')
    else:
        print('Base de datos lista.')

with app.app_context():
    db.create_all()
    if not User.query.first():
        admin = User(username=os.getenv('ADMIN_USERNAME', 'admin'), role='Administrador')
        admin.set_password(os.getenv('ADMIN_PASSWORD', 'Admin123!'))
        db.session.add(admin); db.session.commit()

if __name__ == '__main__':
    app.run(debug=True)
